import lexhub_backend.common;
import lexhub_backend.database_service as database;

import ballerina/http;
import ballerina/io;
import ballerina/jwt;
import ballerina/sql;

// JWT configuration is now in jwt_utils.bal to avoid duplication

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000", "*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"]
    }
}
service /auth on database:mainListener {

    // Login resource - issues JWT token with role claim
    resource function post login(@http:Payload Credentials credentials) returns json|error {        sql:ParameterizedQuery query = `SELECT u.name, u.id, u.email, u.password, u.user_type
                                       FROM users u 
                                       WHERE u.email = ${credentials.email}`;
        UserAuthData|sql:Error result = database:dbClient->queryRow(query);

        if (result is sql:Error) {
            if (result is sql:NoRowsError) {
                io:println("Invalid email: " + credentials.email);
                return error("Invalid email");
            } else {
                io:println("Database error: " + result.message());
                return error("Database error");
            }
        }
  // Verify password using BCrypt
        boolean|error passwordMatches = common:verifyPassword(credentials.password, result.password);
        if (passwordMatches is error) {
            io:println("Password verification error: " + passwordMatches.message());
            return error("Password verification failed");
        }

        if (passwordMatches) {
            // Create a new mutable IssuerConfig
            jwt:IssuerConfig config = {
                username: credentials.email,
                issuer: jwtIssuerConfig.issuer,
                audience: jwtIssuerConfig.audience,
                signatureConfig: jwtIssuerConfig.signatureConfig,
                expTime: jwtIssuerConfig.expTime,
                customClaims: {
                     "role": result.user_type,
                    "name": result.name,
                    "id": result.id,
                    "email": result.email
                }
            };            string token = check jwt:issue(config);

            return {
                token: token,
                redirect: "/home",
                user: {
                    name: result.name,
                    email: result.email,
                    role: result.user_type,
                    id: result.id
                }
            };
        } else {
            io:println("Invalid password for user: " + credentials.email);
            return error("Invalid password");
        }
    }
    // Protected resource - requires valid JWT token with any role
    resource function get protected(http:Request req) returns string|error {
        io:println("Accessing protected resource");

        string|error authHeader = req.getHeader("Authorization");
        if (authHeader is error) {
            io:println("Authorization header not found");
            return error("Authorization header not found");
        }

        string token = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : authHeader;

        jwt:Payload|error payload = check jwt:validate(token, common:jwtValidatorConfig);
        if (payload is jwt:Payload) {
            io:println("Protected data accessed successfully by user: " + <string>payload["username"]);
            return "Protected data accessed successfully";
        } else {
            io:println("Unauthorized access attempt");
            return error("Unauthorized");
        }
    }

    // Admin-only resource - requires JWT with role "admin"
    resource function get adminResource(http:Request req) returns string|error {
        string|error authHeader = req.getHeader("Authorization");
        if (authHeader is error) {
            io:println("Authorization header not found");
            return error("Authorization header not found");
        }

        string token = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : authHeader;

        jwt:Payload|error payload = check jwt:validate(token, common:jwtValidatorConfig);
        if (payload is jwt:Payload) {
            anydata roleClaim = payload["role"];
            if (roleClaim is string && roleClaim == "admin") {
                io:println("Admin resource accessed by: " + <string>payload["username"]);
                return "Welcome Admin! This is a restricted resource.";
            } else {
                io:println("Forbidden: User role is not admin");
                return error("Forbidden: You do not have permission to access this resource");
            }
        } else {
            io:println("Unauthorized access attempt");
            return error("Unauthorized");
        }
    }    resource function post registerUser (@http:Payload User user) returns json | error?{


        string hashpassword = check common:hashPassword(user.password ?: "");

        sql:ExecutionResult result = check database:dbClient->execute(
            `INSERT INTO users (name, email, password, user_type) 
             VALUES (${user.name}, ${user.email}, ${hashpassword}, 'user')`
        );

        if result.affectedRowCount > 0 {
            return { message: "User registered successfully" };
        } else {
            return error("User registration failed");

    }
}        resource function post registerLawyer (@http:Payload Lawyer lawyer) returns error? | json{

        string? hashpassword = check common:hashPassword(lawyer.password ?: "");

        // First insert into users table
        sql:ExecutionResult result = check database:dbClient->execute(
            `INSERT INTO users (name, email, password, user_type) 
             VALUES (${lawyer.name}, ${lawyer.email}, ${hashpassword}, 'lawyer')`
        );
        
        if result.affectedRowCount > 0 {
            // Get the generated user ID
            int userId = check database:dbClient->queryRow(`SELECT id FROM users WHERE email = ${lawyer.email}`);
            
            // Now insert into lawyers table
            sql:ExecutionResult lawyerResult = check database:dbClient->execute(
                `INSERT INTO lawyers (user_id, phone, license_number, specialty) 
                 VALUES (${userId}, ${lawyer.phone}, ${lawyer.license_number}, ${lawyer.specialty})`
            );
            
            if lawyerResult.affectedRowCount > 0 {
                return { message: "Lawyer registered successfully" };
            } else {
                return error("Lawyer registration failed at lawyer details step");
            }
        } else {
            return error("Lawyer registration failed");
        }

    }

}

public function startAuthService() returns error? {
    io:println("Auth service started on port 8080");
}
