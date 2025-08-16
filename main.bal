import ballerina/http;
import ballerina/log;
import ballerina/time;
import lexhub_backend.database;
import lexhub_backend.auth;
import lexhub_backend.user;

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
    
    # User registration endpoint
    resource function post auth/register(@http:Payload json registerRequest) returns json|http:BadRequest {
        log:printInfo("User registration endpoint accessed");
        
        // Extract registration data
        json|error emailResult = registerRequest.email;
        json|error passwordResult = registerRequest.password;
        json|error nameResult = registerRequest.name;
        json|error roleResult = registerRequest.role;
        
        if emailResult is error || passwordResult is error || nameResult is error || roleResult is error {
            http:BadRequest badRequest = {
                body: {
                    "error": "Invalid request format",
                    "message": "Email, password, name, and role are required"
                }
            };
            return badRequest;
        }
        
        string email = emailResult.toString();
        string password = passwordResult.toString();
        string name = nameResult.toString();
        string role = roleResult.toString();
        
        // Create user
        auth:User|error newUser = user:createUser(email, password, name, role);
        
        if newUser is error {
            http:BadRequest badRequest = {
                body: {
                    "error": "Registration failed",
                    "message": newUser.message()
                }
            };
            return badRequest;
        }
        
        // Generate JWT token
        auth:JwtConfig jwtConfig = auth:getDefaultJwtConfig();
        string|error token = auth:generateToken(newUser, jwtConfig);
        
        if token is error {
            http:BadRequest badRequest = {
                body: {
                    "error": "Token generation failed",
                    "message": token.message()
                }
            };
            return badRequest;
        }
        
        return auth:createAuthResponse(newUser, token);
    }
    
    # Lawyer registration endpoint
    resource function post auth/register/lawyer(@http:Payload json registerRequest) returns json|http:BadRequest {
        log:printInfo("Lawyer registration endpoint accessed");
        
        // Extract lawyer registration data
        json|error emailResult = registerRequest.email;
        json|error passwordResult = registerRequest.password;
        json|error nameResult = registerRequest.name;
        json|error phoneResult = registerRequest.phone;
        json|error licenseResult = registerRequest.licenseNumber;
        json|error specialtyResult = registerRequest.specialty;
        
        if emailResult is error || passwordResult is error || nameResult is error || 
           phoneResult is error || licenseResult is error || specialtyResult is error {
            http:BadRequest badRequest = {
                body: {
                    "error": "Invalid request format",
                    "message": "All fields are required for lawyer registration"
                }
            };
            return badRequest;
        }
        
        string email = emailResult.toString();
        string password = passwordResult.toString();
        string name = nameResult.toString();
        string phone = phoneResult.toString();
        string licenseNumber = licenseResult.toString();
        string specialty = specialtyResult.toString();
        
        // Create lawyer
        auth:User|error newLawyer = user:createLawyer(email, password, name, phone, licenseNumber, specialty);
        
        if newLawyer is error {
            http:BadRequest badRequest = {
                body: {
                    "error": "Lawyer registration failed",
                    "message": newLawyer.message()
                }
            };
            return badRequest;
        }
        
        // Generate JWT token
        auth:JwtConfig jwtConfig = auth:getDefaultJwtConfig();
        string|error token = auth:generateToken(newLawyer, jwtConfig);
        
        if token is error {
            http:BadRequest badRequest = {
                body: {
                    "error": "Token generation failed",
                    "message": token.message()
                }
            };
            return badRequest;
        }
        
        return auth:createAuthResponse(newLawyer, token);
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
    
    # Enhanced login endpoint with email/password support
    resource function post auth/login(@http:Payload json loginRequest) returns json|http:BadRequest {
        log:printInfo("Login endpoint accessed");
        
        // Check if it's Firebase or email/password login
        json|error idTokenResult = loginRequest.idToken;
        json|error emailResult = loginRequest.email;
        json|error passwordResult = loginRequest.password;
        
        // Firebase authentication
        if idTokenResult is json && idTokenResult.toString() != "null" && idTokenResult.toString() != "" {
            string idToken = idTokenResult.toString();
            
            // Authenticate with Firebase
            auth:User|error user = auth:authenticateWithFirebase(idToken);
            
            if user is error {
                http:BadRequest badRequest = {
                    body: {
                        "error": "Firebase authentication failed",
                        "message": user.message()
                    }
                };
                return badRequest;
            }
            
            // Generate JWT token
            auth:JwtConfig jwtConfig = auth:getDefaultJwtConfig();
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
            
            return auth:createAuthResponse(user, token);
        }
        
        // Email/password authentication
        if emailResult is json && passwordResult is json {
            string email = emailResult.toString();
            string password = passwordResult.toString();
            
            // Authenticate with email and password
            auth:User|error user = user:authenticateLogin(email, password);
            
            if user is error {
                http:BadRequest badRequest = {
                    body: {
                        "error": "Login failed",
                        "message": user.message()
                    }
                };
                return badRequest;
            }
            
            // Generate JWT token
            auth:JwtConfig jwtConfig = auth:getDefaultJwtConfig();
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
            
            return auth:createAuthResponse(user, token);
        }
        
        // Invalid request format
        http:BadRequest badRequest = {
            body: {
                "error": "Invalid request format",
                "message": "Either idToken or email/password combination is required"
            }
        };
        return badRequest;
    }
    
    # User profile endpoint
    resource function get auth/profile(http:Request req) returns json|http:Unauthorized|http:BadRequest {
        log:printInfo("Profile endpoint accessed");
        
        // Extract JWT token from Authorization header
        string|error authHeader = req.getHeader("Authorization");
        if authHeader is error {
            http:Unauthorized unauthorized = {
                body: {
                    "error": "Unauthorized",
                    "message": "Authorization header is required"
                }
            };
            return unauthorized;
        }
        
        if !authHeader.startsWith("Bearer ") {
            http:Unauthorized unauthorized = {
                body: {
                    "error": "Unauthorized", 
                    "message": "Bearer token is required"
                }
            };
            return unauthorized;
        }
        
        string token = authHeader.substring(7); // Remove "Bearer "
        
        // Validate token
        auth:JwtConfig jwtConfig = auth:getDefaultJwtConfig();
        var payload = auth:validateToken(token, jwtConfig);
        
        if payload is error {
            http:Unauthorized unauthorized = {
                body: {
                    "error": "Unauthorized",
                    "message": "Invalid or expired token"
                }
            };
            return unauthorized;
        }
        
        // Extract user from token (simplified response)
        return {
            "message": "Profile retrieved successfully",
            "user": payload.toJson()
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
