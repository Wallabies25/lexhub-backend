import ballerina/http;
import ballerina/log;
import ballerina/time;
import lexhub_backend.database;
import lexhub_backend.auth;
import lexhub_backend.user;
import lexhub_backend.security;

# Configuration for the HTTP listener
configurable int port = 8080;

# CORS configuration for frontend integration
http:CorsConfig corsConfig = {
    allowOrigins: ["http://localhost:3000", "http://localhost:5173", "https://lexhub-frontend.vercel.app"],
    allowCredentials: true,
    allowHeaders: ["Content-Type", "Authorization"],
    allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    maxAge: 84900
};

# HTTP service for LexHub Backend with CORS
@http:ServiceConfig {
    cors: corsConfig
}
service /api on new http:Listener(port) {
    
    # Health check endpoint
    # + return - JSON response with service health status
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
    # + registerRequest - User registration data including email, password, name, and role
    # + return - JSON response with user data and token, or error response
    resource function post auth/register(@http:Payload json registerRequest) returns json|http:BadRequest|http:InternalServerError {
        log:printInfo("User registration endpoint accessed");
        
        // Add security headers
        map<string> securityHeaders = security:getSecurityHeaders();
        
        // Extract registration data
        json|error emailResult = registerRequest.email;
        json|error passwordResult = registerRequest.password;
        json|error nameResult = registerRequest.name;
        json|error roleResult = registerRequest.role;
        
        if emailResult is error || passwordResult is error || nameResult is error || roleResult is error {
            http:BadRequest badRequest = {
                headers: securityHeaders,
                body: {
                    "error": "Invalid request format",
                    "message": "Email, password, name, and role are required",
                    "code": "VALIDATION_ERROR"
                }
            };
            return badRequest;
        }
        
        string email = emailResult.toString();
        string password = passwordResult.toString();
        string name = nameResult.toString();
        string role = roleResult.toString();
        
        // Security validation
        if security:containsSqlInjection(email) || security:containsXss(email) ||
           security:containsSqlInjection(name) || security:containsXss(name) {
            http:BadRequest badRequest = {
                headers: securityHeaders,
                body: {
                    "error": "Invalid input detected",
                    "message": "Please provide valid input data",
                    "code": "SECURITY_ERROR"
                }
            };
            return badRequest;
        }
        
        // Create user
        auth:User|error newUser = user:createUser(email, password, name, role);
        
        if newUser is error {
            log:printError("User registration failed: " + newUser.message());
            http:BadRequest badRequest = {
                headers: securityHeaders,
                body: {
                    "error": "Registration failed",
                    "message": newUser.message(),
                    "code": "REGISTRATION_ERROR"
                }
            };
            return badRequest;
        }
        
        // Generate JWT token
        auth:JwtConfig jwtConfig = auth:getDefaultJwtConfig();
        string|error token = auth:generateToken(newUser, jwtConfig);
        
        if token is error {
            log:printError("Token generation failed: " + token.message());
            http:InternalServerError serverError = {
                headers: securityHeaders,
                body: {
                    "error": "Token generation failed",
                    "message": "Unable to generate authentication token",
                    "code": "TOKEN_ERROR"
                }
            };
            return serverError;
        }
        
        json response = auth:createAuthResponse(newUser, token);
        return response;
    }
    
    # Lawyer registration endpoint
    # + registerRequest - Lawyer registration data
    # + return - JSON response with lawyer data and token, or error response
    resource function post auth/register/lawyer(@http:Payload json registerRequest) returns json|http:BadRequest|http:InternalServerError {
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
    # + search - Optional search parameter for filtering statutes
    # + return - JSON response with statutes data
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
    # + loginRequest - Login credentials (email/password or Firebase token)
    # + return - JSON response with user data and token, or error response
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
    # + req - HTTP request containing authorization header
    # + return - JSON response with user profile data, or error response  
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
    # + query - Query data for IP law questions
    # + return - JSON response with query results
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
