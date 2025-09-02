import lexhub_backend.common;
import lexhub_backend.database_service as database;

import ballerina/http;
import ballerina/io;
import ballerina/jwt;
import ballerina/sql;
import ballerina/time;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:5173", "*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"]
    }
}
service /consultations on database:mainListener {

    // Book a consultation with a lawyer
    resource function post book(@http:Payload ConsultationBooking booking, http:Request req) returns json|error {
        // Validate JWT token first
        string|error authHeader = req.getHeader("Authorization");
        if (authHeader is error) {
            return error("Authorization header not found");
        }

        string token = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : authHeader;
        jwt:Payload|error payload = check jwt:validate(token, common:jwtValidatorConfig);
        if (payload is error) {
            return error("Unauthorized");
        }
        
        // Get user ID from token
        anydata userId = payload["id"];
        if (!(userId is int)) {
            return error("Invalid user ID in token");
        }
        
        // Create a unique consultation ID (in real system, this would be auto-generated)
        string consultationId = userId.toString() + "-" + booking.lawyer_id.toString() + "-" + time:utcNow().toString();
        
        // Insert booking into database
        sql:ExecutionResult result = check database:dbClient->execute(
            `INSERT INTO consultations (
                user_id, lawyer_id, consultation_date, consultation_time, 
                topic, status, notes, created_at
            ) VALUES (
                ${userId}, ${booking.lawyer_id}, ${booking.date}, ${booking.time}, 
                ${booking.topic}, 'pending', ${booking.notes}, CURRENT_TIMESTAMP
            )`
        );
        
        if (result.affectedRowCount > 0) {
            return {
                "message": "Consultation booked successfully",
                "consultation_id": consultationId,
                "status": "pending",
                "lawyer_id": booking.lawyer_id,
                "date": booking.date,
                "time": booking.time
            };
        } else {
            return error("Failed to book consultation");
        }
    }
    
    // Get user's consultations
    resource function get user(http:Request req) returns ConsultationDetail[]|error {
        // Validate JWT token
        string|error authHeader = req.getHeader("Authorization");
        if (authHeader is error) {
            return error("Authorization header not found");
        }

        string token = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : authHeader;
        jwt:Payload|error payload = check jwt:validate(token, common:jwtValidatorConfig);
        if (payload is error) {
            return error("Unauthorized");
        }
        
        // Get user ID from token
        anydata userId = payload["id"];
        if (!(userId is int)) {
            return error("Invalid user ID in token");
        }
        
        // Query consultations
        sql:ParameterizedQuery query = `
            SELECT c.id, c.lawyer_id, c.consultation_date, c.consultation_time, c.topic, 
                   c.status, c.notes, c.created_at, u.name as lawyer_name
            FROM consultations c
            JOIN users u ON c.lawyer_id = u.id
            WHERE c.user_id = ${userId}
            ORDER BY c.consultation_date DESC, c.consultation_time DESC
        `;
        
        stream<ConsultationDetail, sql:Error?> resultStream = database:dbClient->query(query);
        
        ConsultationDetail[] consultations = [];
        check from ConsultationDetail consultation in resultStream
            do {
                consultations.push(consultation);
            };
        
        return consultations;
    }
    
    // Get lawyer's upcoming consultations
    resource function get lawyer(http:Request req) returns LawyerConsultationView[]|error {
        // Validate JWT token
        string|error authHeader = req.getHeader("Authorization");
        if (authHeader is error) {
            return error("Authorization header not found");
        }

        string token = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : authHeader;
        jwt:Payload|error payload = check jwt:validate(token, common:jwtValidatorConfig);
        if (payload is error) {
            return error("Unauthorized");
        }
        
        // Get user ID from token and verify lawyer role
        anydata userId = payload["id"];
        anydata userRole = payload["role"];
        
        if (!(userId is int) || !(userRole is string) || userRole != "lawyer") {
            return error("Unauthorized. Only lawyers can access this endpoint");
        }
        
        // Query consultations
        sql:ParameterizedQuery query = `
            SELECT c.id, c.user_id as client_id, c.consultation_date, c.consultation_time, c.topic, 
                   c.status, c.notes, c.created_at, u.name as client_name
            FROM consultations c
            JOIN users u ON c.user_id = u.id
            WHERE c.lawyer_id = ${userId}
            ORDER BY c.consultation_date, c.consultation_time
        `;
        
        stream<LawyerConsultationView, sql:Error?> resultStream = database:dbClient->query(query);
        
        LawyerConsultationView[] consultations = [];
        check from LawyerConsultationView consultation in resultStream
            do {
                consultations.push(consultation);
            };
        
        return consultations;
    }
    
    // Update consultation status (accept/reject/complete)
    resource function put status/[int consultationId](@http:Payload ConsultationStatusUpdate statusUpdate, http:Request req) returns json|error {
        // Validate JWT token
        string|error authHeader = req.getHeader("Authorization");
        if (authHeader is error) {
            return error("Authorization header not found");
        }

        string token = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : authHeader;
        jwt:Payload|error payload = check jwt:validate(token, common:jwtValidatorConfig);
        if (payload is error) {
            return error("Unauthorized");
        }
        
        // Get user ID from token and verify lawyer role for certain actions
        anydata userId = payload["id"];
        anydata userRole = payload["role"];
        
        if (!(userId is int)) {
            return error("Invalid user ID in token");
        }
        
        // For accepting/rejecting, verify the user is the lawyer assigned to this consultation
        if (statusUpdate.status == "accepted" || statusUpdate.status == "rejected") {
            if (!(userRole is string) || userRole != "lawyer") {
                return error("Unauthorized. Only lawyers can accept or reject consultations");
            }
            
            // Verify this lawyer is assigned to this consultation
            boolean isAssigned = check verifyLawyerConsultation(consultationId, <int>userId);
            if (!isAssigned) {
                return error("Unauthorized. You are not assigned to this consultation");
            }
        }
        
        // Update consultation status
        sql:ExecutionResult result = check database:dbClient->execute(
            `UPDATE consultations 
             SET status = ${statusUpdate.status},
                 notes = CONCAT(notes, '\n', ${statusUpdate.notes ?: ""})
             WHERE id = ${consultationId}`
        );
        
        if (result.affectedRowCount > 0) {
            return {
                "message": "Consultation status updated to " + statusUpdate.status,
                "consultation_id": consultationId
            };
        } else {
            return error("Consultation not found or status update failed");
        }
    }
    
    // Add review after consultation
    resource function post review/[int consultationId](@http:Payload ConsultationReview review, http:Request req) returns json|error {
        // Validate JWT token
        string|error authHeader = req.getHeader("Authorization");
        if (authHeader is error) {
            return error("Authorization header not found");
        }

        string token = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : authHeader;
        jwt:Payload|error payload = check jwt:validate(token, common:jwtValidatorConfig);
        if (payload is error) {
            return error("Unauthorized");
        }
        
        // Get user ID from token
        anydata userId = payload["id"];
        if (!(userId is int)) {
            return error("Invalid user ID in token");
        }
        
        // Verify this is the user's consultation
        boolean isUserConsultation = check verifyUserConsultation(consultationId, <int>userId);
        if (!isUserConsultation) {
            return error("Unauthorized. This is not your consultation");
        }
        
        // Get lawyer ID for this consultation
        int lawyerId = check getLawyerIdFromConsultation(consultationId);
        
        // Insert review
        sql:ExecutionResult result = check database:dbClient->execute(
            `INSERT INTO reviews (
                user_id, lawyer_id, consultation_id, rating, 
                review_text, created_at
            ) VALUES (
                ${userId}, ${lawyerId}, ${consultationId}, ${review.rating},
                ${review.review_text}, CURRENT_TIMESTAMP
            )`
        );
        
        if (result.affectedRowCount > 0) {
            // Update lawyer's average rating
            _ = check updateLawyerRating(lawyerId);
            
            return {
                "message": "Review submitted successfully",
                "consultation_id": consultationId,
                "rating": review.rating
            };
        } else {
            return error("Failed to submit review");
        }
    }
}

// Helper functions

// Verify if a consultation belongs to a specific lawyer
function verifyLawyerConsultation(int consultationId, int lawyerId) returns boolean|error {
    int count = check database:dbClient->queryRow(
        `SELECT COUNT(*) FROM consultations 
         WHERE id = ${consultationId} AND lawyer_id = ${lawyerId}`
    );
    
    return count > 0;
}

// Verify if a consultation belongs to a specific user
function verifyUserConsultation(int consultationId, int userId) returns boolean|error {
    int count = check database:dbClient->queryRow(
        `SELECT COUNT(*) FROM consultations 
         WHERE id = ${consultationId} AND user_id = ${userId}`
    );
    
    return count > 0;
}

// Get lawyer ID from consultation
function getLawyerIdFromConsultation(int consultationId) returns int|error {
    return check database:dbClient->queryRow(
        `SELECT lawyer_id FROM consultations WHERE id = ${consultationId}`
    );
}

// Update lawyer's average rating
function updateLawyerRating(int lawyerId) returns float|error {
    float avgRating = check database:dbClient->queryRow(
        `SELECT AVG(rating) FROM reviews WHERE lawyer_id = ${lawyerId}`
    );
    
    sql:ExecutionResult _ = check database:dbClient->execute(
        `UPDATE lawyers SET rating = ${avgRating}, 
         review_count = (SELECT COUNT(*) FROM reviews WHERE lawyer_id = ${lawyerId})
         WHERE user_id = ${lawyerId}`
    );
    
    return avgRating;
}

public function startConsultationService() returns error? {
    io:println("Consultation service started on port 8080");
}
