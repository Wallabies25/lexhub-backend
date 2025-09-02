import lexhub_backend.common;
import lexhub_backend.database_service as database;

import ballerina/http;
import ballerina/io;
import ballerina/jwt;
import ballerina/sql;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:5173", "*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE"],
       allowHeaders: ["Content-Type", "Authorization"]
    }
}
service /users on database:mainListener {

    // Get all users with optional filtering by type
    resource function get profiles(string? user_type = "all") returns UserProfile[]|error {
        sql:ParameterizedQuery query;
        
        if user_type == "all" {
            query = `SELECT u.id, u.name, u.email, u.user_type FROM users u`;
        } else {
            query = `SELECT u.id, u.name, u.email, u.user_type FROM users u WHERE u.user_type = ${user_type}`;
        }
        
        stream<UserProfile, sql:Error?> resultStream = database:dbClient->query(query);
        
        UserProfile[] users = [];
        check from UserProfile user in resultStream
            do {
                users.push(user);
            };
        
        return users;
    }
    
    // Get current user profile from JWT token
    resource function get current(http:Request req) returns UserProfileDetail|error {
        // Extract the token from Authorization header
        string|error authHeader = req.getHeader("Authorization");
        if (authHeader is error) {
            return error("Authorization header not found");
        }

        string token = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : authHeader;

        jwt:Payload|error payload = check jwt:validate(token, common:jwtValidatorConfig);
        if (payload is error) {
            return error("Unauthorized");
        }
        
        // Extract user information from token claims
        anydata userId = payload["id"];
        anydata userName = payload["username"];
        anydata userEmail = payload["email"];
        anydata userRole = payload["role"];
        
        if (userId is int && userName is string && userEmail is string && userRole is string) {
            // Create basic profile from token data
            UserProfileDetail profile = {
                id: userId,
                name: userName,
                email: userEmail,
                user_type: userRole,
                joined_date: "2023-05-15", // Dummy date since we don't store this
                profile_picture: "/images/avatars/avatar_" + userId.toString() + ".jpg" // Default image
            };
            
            // If user is a lawyer, fetch additional lawyer details
            if (userRole == "lawyer") {
                sql:ParameterizedQuery lawyerQuery = `SELECT l.phone, l.license_number, l.specialty 
                                                    FROM lawyers l WHERE l.user_id = ${userId}`;
                LawyerDetail|sql:Error lawyerResult = database:dbClient->queryRow(lawyerQuery);
                
                if (lawyerResult is LawyerDetail) {
                    profile.lawyer_details = {
                        phone: lawyerResult.phone,
                        license_number: lawyerResult.license_number,
                        specialty: lawyerResult.specialty,
                        cases_handled: 15, // Dummy data
                        success_rate: "85%" // Dummy data
                    };
                }
            }
            
            return profile;
        }
        
        return error("Invalid token payload");
    }
    
    // Get user profile by ID
    resource function get profile/[int userId](http:Request req) returns UserProfileDetail|error {
        // Verify JWT first
        string|error authHeader = req.getHeader("Authorization");
        if (authHeader is error) {
            return error("Authorization header not found");
        }

        string token = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : authHeader;

        jwt:Payload|error payload = check jwt:validate(token, common:jwtValidatorConfig);
        if (payload is error) {
            return error("Unauthorized");
        }
        
        // Get basic user info
        sql:ParameterizedQuery userQuery = `SELECT u.id, u.name, u.email, u.user_type 
                                           FROM users u WHERE u.id = ${userId}`;
        UserProfile|sql:Error userResult = database:dbClient->queryRow(userQuery);
        
        if (userResult is sql:Error) {
            if (userResult is sql:NoRowsError) {
                return error("User not found");
            }
            return error("Database error: " + userResult.message());
        }
        
        UserProfileDetail profile = {
            id: userResult.id,
            name: userResult.name,
            email: userResult.email,
            user_type: userResult.user_type,
            joined_date: "2023-05-15", // Dummy date since the actual join date isn't in your schema
            profile_picture: "/images/avatars/avatar_" + userId.toString() + ".jpg" // Dummy profile picture
        };
        
        // If user is a lawyer, add lawyer details
        if (userResult.user_type == "lawyer") {
            sql:ParameterizedQuery lawyerQuery = `SELECT l.phone, l.license_number, l.specialty 
                                                FROM lawyers l WHERE l.user_id = ${userId}`;
            LawyerDetail|sql:Error lawyerResult = database:dbClient->queryRow(lawyerQuery);
            
            if (lawyerResult is LawyerDetail) {
                profile.lawyer_details = {
                    phone: lawyerResult.phone,
                    license_number: lawyerResult.license_number,
                    specialty: lawyerResult.specialty,
                    cases_handled: 15, // Dummy data
                    success_rate: "85%" // Dummy data
                };
            }
        }
        
        return profile;
    }
    
    // Create or update user profile
    resource function put profile/[int userId](@http:Payload UserProfileUpdate profile, http:Request req) returns json|error {
        // Verify JWT first and check if user is authorized
        string|error authHeader = req.getHeader("Authorization");
        if (authHeader is error) {
            return error("Authorization header not found");
        }

        string token = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : authHeader;

        jwt:Payload|error payload = check jwt:validate(token, common:jwtValidatorConfig);
        if (payload is error) {
            return error("Unauthorized");
        }
        
        // Ensure the user can only update their own profile unless they're an admin
        anydata userIdFromToken = payload["id"];
        anydata userRole = payload["role"];
        
        if (userIdFromToken is int && userRole is string) {
            if (userIdFromToken != userId && userRole != "admin") {
                return error("You don't have permission to update this profile");
            }
        } else {
            return error("Invalid token");
        }
        
        // Update the user profile
        sql:ExecutionResult result = check database:dbClient->execute(
            `UPDATE users SET name = ${profile.name} WHERE id = ${userId}`
        );
        
        // If it's a lawyer profile and lawyer details are provided, update those too
        if (profile.lawyer_details is LawyerProfileUpdateDetail) {
            LawyerProfileUpdateDetail lawyerDetails = <LawyerProfileUpdateDetail>profile.lawyer_details;
            sql:ExecutionResult lawyerResult = check database:dbClient->execute(
                `UPDATE lawyers SET 
                 phone = ${lawyerDetails.phone},
                 specialty = ${lawyerDetails.specialty}
                 WHERE user_id = ${userId}`
            );
        }
        
        return {
            message: "Profile updated successfully"
        };
    }
    
    // Example endpoint with dummy data for demonstration
    resource function get demo/profiles() returns json {
        return [
            {
                "id": 1,
                "name": "John Doe",
                "email": "john@example.com",
                "user_type": "user",
                "joined_date": "2023-01-15",
                "profile_picture": "/images/avatars/avatar_1.jpg",
                "bio": "Regular user interested in legal assistance"
            },
            {
                "id": 2,
                "name": "Jane Smith",
                "email": "jane@lexhub.com",
                "user_type": "lawyer",
                "joined_date": "2022-11-05",
                "profile_picture": "/images/avatars/avatar_2.jpg",
                "bio": "Experienced corporate lawyer with 10 years of practice",
                "lawyer_details": {
                    "phone": "555-123-4567",
                "license_number": "LB12345",
                "specialty": "Corporate Law",
                "cases_handled": 78,
                "success_rate": "92%",
                "education": "Harvard Law School",
                "certifications": ["Bar Association", "Legal Ethics Board"]
                }
            },
            {
                "id": 3,
                "name": "Admin User",
                "email": "admin@lexhub.com",
                "user_type": "admin",
                "joined_date": "2022-01-01",
                "profile_picture": "/images/avatars/avatar_3.jpg",
                "bio": "System administrator"
            }
        ];
    }
}

// Start user service
public function startUserServiceApi() returns error? {
    io:println("User service started on port 8080");
}
