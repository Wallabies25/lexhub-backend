import lexhub_backend.common;
import lexhub_backend.database_service as database;

import ballerina/http;
import ballerina/io;
import ballerina/jwt;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:5173", "*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"]
    }
}
service /profile on database:mainListener {

    // Get current user's profile info for display in the navbar
    resource function get navbar(http:Request req) returns json|error {
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
        anydata userName = payload["username"] ?: payload["name"]; // Handle both possible claim names
        anydata userEmail = payload["email"];
        anydata userRole = payload["role"];
        
        if (userId is int && userName is string && userEmail is string && userRole is string) {
            return {
                "id": userId,
                "name": userName,
                "email": userEmail,
                "role": userRole,
                "profile_picture": "/images/avatars/avatar_" + userId.toString() + ".jpg" // Default profile picture
            };
        }
        
        return error("Invalid token payload");
    }
    
    // Update user's profile image
    resource function post avatar(@http:Payload byte[] imageData, http:Request req) returns json|error {
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
        
        // In a real implementation, we would save the image to a file or database
        // For this demo, we'll just return success
        return {
            "message": "Profile image updated successfully",
            "url": "/api/profile/avatar/" + <string>payload["id"]
        };
    }
    
    // Redirect to home page after login
    resource function get redirect() returns http:Response {
        http:Response response = new;
        response.statusCode = 302;
        response.setHeader("Location", "/home");
        return response;
    }
}

public function startProfileServiceds() returns error? {
    io:println("Profile service started on port 8080");
}
