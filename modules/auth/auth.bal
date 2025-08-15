import ballerina/jwt;
import ballerina/log;

# User record type
public type User record {
    string id;
    string email;
    string name;
    string role;
};

# JWT configuration
public type JwtConfig record {
    string secret;
    int expiry;
};

# Generate JWT token for user
public function generateToken(User user, JwtConfig config) returns string|jwt:Error {
    jwt:IssuerConfig issuerConfig = {
        username: user.email,
        issuer: "lexhub-backend",
        audience: ["lexhub-users"],
        expTime: <decimal>config.expiry,
        customClaims: {
            "user_id": user.id,
            "name": user.name,
            "role": user.role
        }
    };
    
    string token = check jwt:issue(issuerConfig);
    log:printInfo("JWT token generated for user: " + user.email);
    return token;
}

# Validate JWT token
public function validateToken(string token, JwtConfig config) returns jwt:Payload|jwt:Error {
    jwt:ValidatorConfig validatorConfig = {
        issuer: "lexhub-backend",
        audience: ["lexhub-users"]
    };
    
    jwt:Payload payload = check jwt:validate(token, validatorConfig);
    log:printInfo("JWT token validated successfully");
    return payload;
}

# Extract user from JWT payload
public function extractUser(jwt:Payload payload) returns User {
    anydata customClaimsData = payload["customClaims"] ?: {};
    map<anydata> customClaims = <map<anydata>>customClaimsData;
    
    return {
        id: customClaims["user_id"].toString(),
        email: payload.sub ?: "",
        name: customClaims["name"].toString(),
        role: customClaims["role"].toString()
    };
}

# Firebase authentication placeholder
public function authenticateWithFirebase(string idToken) returns User|error {
    log:printInfo("Firebase authentication - placeholder implementation");
    
    // This is a placeholder - actual Firebase token verification would go here
    return {
        id: "firebase_user_id",
        email: "user@example.com",
        name: "Firebase User",
        role: "user"
    };
}
