
import lexhub_backend.database_service as database;

import ballerina/http;
import ballerina/io;
import ballerina/sql;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:5173", "*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"]
    }
}
service /lawyers on database:mainListener {

    // Search for lawyers with optional filters
    resource function get search(string? query = "", string? specialty = "", float? min_rating = 0.0) returns LawyerSearchResult[]|error {
        sql:ParameterizedQuery sqlQuery;
        string likePattern = "%" + (query ?: "") + "%";
        
        if (specialty != "") {
            sqlQuery = `
                SELECT u.id, u.name, u.email, l.specialty, l.rating, l.review_count, l.hourly_rate
                FROM users u
                JOIN lawyers l ON u.id = l.user_id
                WHERE u.user_type = 'lawyer'
                AND (u.name LIKE ${likePattern} OR l.specialty LIKE ${likePattern})
                AND l.specialty = ${specialty}
                AND l.rating >= ${min_rating}
                ORDER BY l.rating DESC
            `;
        } else {
            sqlQuery = `
                SELECT u.id, u.name, u.email, l.specialty, l.rating, l.review_count, l.hourly_rate
                FROM users u
                JOIN lawyers l ON u.id = l.user_id
                WHERE u.user_type = 'lawyer'
                AND (u.name LIKE ${likePattern} OR l.specialty LIKE ${likePattern})
                AND l.rating >= ${min_rating}
                ORDER BY l.rating DESC
            `;
        }
        
        stream<LawyerSearchResult, sql:Error?> resultStream = database:dbClient->query(sqlQuery);
        
        LawyerSearchResult[] lawyers = [];
        check from LawyerSearchResult lawyer in resultStream
            do {
                lawyers.push(lawyer);
            };
        
        return lawyers;
    }
    
    // Get lawyer specialties for filtering
    resource function get specialties() returns json|error {
        sql:ParameterizedQuery query = `
            SELECT DISTINCT specialty 
            FROM lawyers
            ORDER BY specialty
        `;
        
        stream<record {|string specialty;|}, sql:Error?> resultStream = database:dbClient->query(query);
        
        string[] specialties = [];
        check from record {| string specialty; |} specialty in resultStream
            do {
                specialties.push(specialty.specialty);
            };
        
        return { specialties: specialties };
    }
    
    // Get detailed lawyer profile with reviews
    resource function get [int lawyerId]() returns LawyerFullProfile|error {
        // Get basic lawyer info
        sql:ParameterizedQuery lawyerQuery = `
            SELECT u.id, u.name, u.email, l.phone, l.specialty, l.license_number, 
                   l.rating, l.review_count, l.hourly_rate
            FROM users u
            JOIN lawyers l ON u.id = l.user_id
            WHERE u.id = ${lawyerId} AND u.user_type = 'lawyer'
        `;
        
        LawyerFullProfile|sql:Error lawyerResult = database:dbClient->queryRow(lawyerQuery);
        
        if (lawyerResult is sql:Error) {
            if (lawyerResult is sql:NoRowsError) {
                return error("Lawyer not found");
            }
            return error("Database error: " + lawyerResult.message());
        }
        
        // Get lawyer reviews
        sql:ParameterizedQuery reviewsQuery = `
            SELECT r.id, r.rating, r.review_text, r.created_at, 
                   u.name as reviewer_name
            FROM reviews r
            JOIN users u ON r.user_id = u.id
            WHERE r.lawyer_id = ${lawyerId}
            ORDER BY r.created_at DESC
            LIMIT 10
        `;
        
        stream<LawyerReview, sql:Error?> reviewsStream = database:dbClient->query(reviewsQuery);
        
        LawyerReview[] reviews = [];
        check from LawyerReview review in reviewsStream
            do {
                reviews.push(review);
            };
        
        lawyerResult.reviews = reviews;
        
        // Get lawyer availability (demo data for now)
        lawyerResult.availability = [
            { day: "Monday", slots: ["9:00 AM - 12:00 PM", "2:00 PM - 5:00 PM"] },
            { day: "Tuesday", slots: ["9:00 AM - 12:00 PM", "2:00 PM - 5:00 PM"] },
            { day: "Wednesday", slots: ["9:00 AM - 12:00 PM", "2:00 PM - 5:00 PM"] },
            { day: "Thursday", slots: ["9:00 AM - 12:00 PM", "2:00 PM - 5:00 PM"] },
            { day: "Friday", slots: ["9:00 AM - 12:00 PM", "2:00 PM - 5:00 PM"] }
        ];
        
        return lawyerResult;
    }
    
    // Get featured lawyers for homepage
    resource function get featured() returns json|error {
        sql:ParameterizedQuery query = `
            SELECT u.id, u.name, u.email, l.specialty, l.rating, l.review_count, l.hourly_rate
            FROM users u
            JOIN lawyers l ON u.id = l.user_id
            WHERE u.user_type = 'lawyer'
            ORDER BY l.rating DESC, l.review_count DESC
            LIMIT 5
        `;
        
        stream<LawyerSearchResult, sql:Error?> resultStream = database:dbClient->query(query);
        
        LawyerSearchResult[] lawyers = [];
        check from LawyerSearchResult lawyer in resultStream
            do {
                lawyers.push(lawyer);
            };
        
        return { featured_lawyers: lawyers };
    }
}

public function startLawyerService() returns error? {
    io:println("Lawyer service started on port 8080");
}
