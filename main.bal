import ballerina/http;
import ballerina/log;
import ballerina/time;
import lexhub_backend.database;
import lexhub_backend.auth;

# Configuration for the HTTP listener
configurable int port = 8080;

# HTTP service for LexHub Backend
service /api on new http:Listener(port) {
    
    # Health check endpoint
    resource function get health() returns json {
        log:printInfo("Health check endpoint accessed");
        return {
            "status": "UP",
            "service": "LexHub Backend",
            "version": "0.1.0",
            "timestamp": time:utcNow()
        };
    }
    
    # Legal statutes endpoint
    resource function get statutes(string? search) returns json {
        log:printInfo("Statutes endpoint accessed");
        
        database:LegalStatute[] statutes = [];
        
        if search is string {
            statutes = database:searchStatutes(search);
        } else {
            statutes = database:getAllStatutes();
        }
        
        return {
            "message": "Legal statutes retrieved successfully",
            "data": statutes.toJson(),
            "count": statutes.length()
        };
    }
    
    # Authentication endpoint
    resource function post auth/login(@http:Payload json loginRequest) returns json|http:BadRequest {
        log:printInfo("Login endpoint accessed");
        
        // Extract Firebase ID token from request
        json|error idTokenResult = loginRequest.idToken;
        if idTokenResult is error {
            http:BadRequest badRequest = {
                body: {
                    "error": "Invalid request format",
                    "message": "Could not extract idToken from request"
                }
            };
            return badRequest;
        }
        
        string idToken = idTokenResult.toString();
        
        if idToken == "null" || idToken == "" {
            http:BadRequest badRequest = {
                body: {
                    "error": "ID token is required",
                    "message": "Firebase ID token must be provided"
                }
            };
            return badRequest;
        }
        
        // Authenticate with Firebase (placeholder)
        auth:User|error user = auth:authenticateWithFirebase(idToken);
        
        if user is error {
            http:BadRequest badRequest = {
                body: {
                    "error": "Authentication failed",
                    "message": user.message()
                }
            };
            return badRequest;
        }
        
        // Generate JWT token
        auth:JwtConfig jwtConfig = {
            secret: "your_jwt_secret_key",
            expiry: 86400  // 24 hours
        };
        
        string|error token = auth:generateToken(user, jwtConfig);
        
        if token is error {
            http:BadRequest badRequest = {
                body: {
                    "error": "Token generation failed",
                    "message": token.message()
                }
            };
            return badRequest;
        }
        
        return {
            "message": "Authentication successful",
            "user": user.toJson(),
            "token": token
        };
    }
    
    # IP law queries endpoint
    resource function post queries(@http:Payload json query) returns json {
        log:printInfo("Queries endpoint accessed");
        return {
            "message": "IP law query processed",
            "query": query,
            "result": "Query processing will be implemented with Gemini AI integration",
            "status": "placeholder"
        };
    }
}

public function main() {
    log:printInfo(string `LexHub Backend started on port ${port}`);
}
