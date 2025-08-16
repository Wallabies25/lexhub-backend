import ballerina/jwt;
import ballerina/log;
import ballerina/time;
import ballerina/crypto;
import ballerina/uuid;
import ballerina/regex;

# Enhanced User record type
public type User record {|
    string id;
    string email;
    string name;
    string role; // "student", "lawyer", "admin", "public"
    string? phone?;
    string? licenseNumber?; // For lawyers only
    string? specialty?; // For lawyers only
    boolean verified;
    boolean mfaEnabled;
    time:Utc createdAt;
    time:Utc updatedAt;
|};

# Enhanced JWT configuration
public type JwtConfig record {|
    string secret;
    int expiry; // in seconds
    string issuer;
    string[] audience;
|};

# Authentication constants
const string DEFAULT_ISSUER = "lexhub-backend";
const string[] DEFAULT_AUDIENCE = ["lexhub-users"];
const int DEFAULT_TOKEN_EXPIRY = 86400; // 24 hours
const int MAX_LOGIN_ATTEMPTS = 5;
const int LOGIN_LOCKOUT_DURATION = 1800; // 30 minutes

# Generate JWT token for user
public function generateToken(User user, JwtConfig config) returns string|jwt:Error {
    jwt:IssuerConfig issuerConfig = {
        username: user.email,
        issuer: config.issuer,
        audience: config.audience,
        expTime: <decimal>config.expiry,
        customClaims: {
            "user_id": user.id,
            "name": user.name,
            "role": user.role,
            "verified": user.verified,
            "mfa_enabled": user.mfaEnabled
        }
    };
    
    string token = check jwt:issue(issuerConfig);
    log:printInfo("JWT token generated for user: " + user.email);
    return token;
}

# Validate JWT token
public function validateToken(string token, JwtConfig config) returns jwt:Payload|jwt:Error {
    jwt:ValidatorConfig validatorConfig = {
        issuer: config.issuer,
        audience: config.audience
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
        role: customClaims["role"].toString(),
        verified: <boolean>customClaims["verified"],
        mfaEnabled: <boolean>customClaims["mfa_enabled"],
        createdAt: time:utcNow(),
        updatedAt: time:utcNow()
    };
}

# Hash password using SHA-256
public function hashPassword(string password) returns string|error {
    byte[] passwordBytes = password.toBytes();
    byte[] hashedBytes = crypto:hashSha256(passwordBytes);
    return hashedBytes.toBase64();
}

# Verify password against hash
public function verifyPassword(string password, string hash) returns boolean|error {
    string hashedPassword = check hashPassword(password);
    return hashedPassword == hash;
}

# Validate email format
public function validateEmail(string email) returns boolean {
    string emailRegex = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$";
    return regex:matches(email, emailRegex);
}

# Validate phone number (Sri Lankan format)
public function validatePhoneNumber(string phone) returns boolean {
    string phoneRegex = "^(\\+94|0)[0-9]{9}$";
    return regex:matches(phone, phoneRegex);
}

# Validate password strength
public function validatePasswordStrength(string password) returns boolean {
    // At least 8 characters, one uppercase, one lowercase, one digit
    if password.length() < 8 {
        return false;
    }
    
    boolean hasUpper = regex:matches(password, ".*[A-Z].*");
    boolean hasLower = regex:matches(password, ".*[a-z].*");
    boolean hasDigit = regex:matches(password, ".*[0-9].*");
    
    return hasUpper && hasLower && hasDigit;
}

# Authenticate user with email and password
public function authenticateUser(string email, string password) returns User|error {
    log:printInfo("Authenticating user: " + email);
    
    // Validate input
    if !validateEmail(email) {
        return error("Invalid email format");
    }
    
    // For testing purposes, simulate password validation
    if password.length() < 6 {
        return error("Invalid credentials");
    }
    
    // Determine user role and details based on email for testing
    string name = "Test User";
    string role = "public";
    boolean verified = false;
    
    if email.includes("lawyer") || email.includes("attorney") {
        name = "Test Lawyer";
        role = "lawyer";
        verified = false; // Lawyers need manual verification
    } else if email.includes("student") || email.includes("university") {
        name = "Test Student";
        role = "student";
        verified = true;
    } else if email.includes("admin") {
        name = "Test Admin";
        role = "admin";
        verified = true;
    } else {
        // Extract name from email for better UX
        string[] emailParts = regex:split(email, "@");
        if emailParts.length() > 0 {
            string localPart = emailParts[0];
            name = regex:replaceAll(localPart, "[._-]", " ");
        }
    }
    
    // Create mock user based on email
    User mockUser = {
        id: uuid:createType1AsString(),
        email: email,
        name: name,
        role: role,
        verified: verified,
        mfaEnabled: false,
        createdAt: time:utcNow(),
        updatedAt: time:utcNow()
    };
    
    return mockUser;
}

# Register new user
public function registerUser(string email, string password, string name, string role) returns User|error {
    log:printInfo("Registering new user: " + email);
    
    // Validate input
    if !validateEmail(email) {
        return error("Invalid email format");
    }
    
    if !validatePasswordStrength(password) {
        return error("Password does not meet strength requirements");
    }
    
    // Hash password
    string hashedPassword = check hashPassword(password);
    
    // Create new user
    User newUser = {
        id: uuid:createType1AsString(),
        email: email,
        name: name,
        role: role,
        verified: false,
        mfaEnabled: false,
        createdAt: time:utcNow(),
        updatedAt: time:utcNow()
    };
    
    log:printInfo("User registered successfully: " + email);
    return newUser;
}

# Register lawyer with additional validation
public function registerLawyer(string email, string password, string name, string phone, 
                             string licenseNumber, string specialty) returns User|error {
    log:printInfo("Registering new lawyer: " + email);
    
    // Validate input
    if !validateEmail(email) {
        return error("Invalid email format");
    }
    
    if !validatePasswordStrength(password) {
        return error("Password does not meet strength requirements");
    }
    
    if !validatePhoneNumber(phone) {
        return error("Invalid phone number format");
    }
    
    if licenseNumber.length() < 5 {
        return error("Invalid license number");
    }
    
    // Hash password
    string hashedPassword = check hashPassword(password);
    
    // Create new lawyer user
    User newLawyer = {
        id: uuid:createType1AsString(),
        email: email,
        name: name,
        role: "lawyer",
        phone: phone,
        licenseNumber: licenseNumber,
        specialty: specialty,
        verified: false, // Lawyers need manual verification
        mfaEnabled: false,
        createdAt: time:utcNow(),
        updatedAt: time:utcNow()
    };
    
    log:printInfo("Lawyer registered successfully: " + email);
    return newLawyer;
}

# Firebase authentication implementation
public function authenticateWithFirebase(string idToken) returns User|error {
    log:printInfo("Firebase authentication - processing ID token");
    
    // In a real implementation, you would:
    // 1. Verify the Firebase ID token using Firebase Admin SDK
    // 2. Extract user information from the verified token
    // 3. Check if user exists in your database or create new user
    
    // Mock implementation for demonstration
    if idToken == "null" || idToken == "" {
        return error("Invalid Firebase ID token");
    }
    
    // This would be replaced with actual Firebase token verification
    User firebaseUser = {
        id: uuid:createType1AsString(),
        email: "firebase.user@example.com",
        name: "Firebase User",
        role: "public",
        verified: true,
        mfaEnabled: false,
        createdAt: time:utcNow(),
        updatedAt: time:utcNow()
    };
    
    log:printInfo("Firebase authentication successful");
    return firebaseUser;
}

# Get default JWT configuration
public function getDefaultJwtConfig() returns JwtConfig {
    return {
        secret: "lexhub_secret_key_change_in_production",
        expiry: DEFAULT_TOKEN_EXPIRY,
        issuer: DEFAULT_ISSUER,
        audience: DEFAULT_AUDIENCE
    };
}

# Create complete authentication response
public function createAuthResponse(User user, string token) returns json {
    return {
        "message": "Authentication successful",
        "user": {
            "id": user.id,
            "email": user.email,
            "name": user.name,
            "role": user.role,
            "verified": user.verified,
            "mfaEnabled": user.mfaEnabled
        },
        "token": token,
        "expiresIn": DEFAULT_TOKEN_EXPIRY
    };
}
