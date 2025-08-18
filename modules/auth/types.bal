// This file contains additional type definitions for the auth module
// Main types are defined in auth.bal to avoid redeclaration issues

import ballerina/time;

# Authentication request types
public type LoginRequest record {|
    string email;
    string password;
    string? mfaCode?;
|};

public type RegisterRequest record {|
    string email;
    string password;
    string name;
    string role;
    string? phone?;
    string? licenseNumber?; // Required for lawyers
    string? specialty?; // For lawyers
|};

public type LawyerRegistrationRequest record {|
    string email;
    string password;
    string name;
    string phone;
    string licenseNumber;
    string specialty;
|};

# Authentication response types
public type AuthResponse record {|
    string token;
    string message;
    int expiresIn;
|};

public type AuthError record {|
    string code;
    string message;
    string? details?;
|};

# Firebase token verification request
public type FirebaseAuthRequest record {|
    string idToken;
    string? expectedRole?;
|};

# User profile update request
public type UserProfileUpdate record {|
    string? name?;
    string? phone?;
    string? specialty?; // For lawyers
    boolean? mfaEnabled?;
|};

# Password reset types
public type PasswordResetRequest record {|
    string email;
|};

public type PasswordResetConfirm record {|
    string token;
    string newPassword;
|};

# Session management
public type UserSession record {|
    string sessionId;
    string userId;
    string token;
    time:Utc createdAt;
    time:Utc expiresAt;
    boolean active;
|};