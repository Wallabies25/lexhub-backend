import ballerina/log;
import ballerina/time;

# User record type (duplicate to avoid circular imports)
public type User record {|
    string id;
    string email;
    string passwordHash;
    string name;
    string role;
    string? phone?;
    string? licenseNumber?;
    string? specialty?;
    boolean verified;
    boolean mfaEnabled;
    time:Utc createdAt;
    time:Utc updatedAt;
|};

# Save user to database using connection module
public function saveUserToDatabase(User user) returns error? {
    log:printInfo(string `Saving user to database: ${user.email}`);
    
    // Use the connection module's insertUser function
    var result = insertUser(user.email, user.passwordHash, user.name, user.role, user?.phone);
    if result is error {
        log:printError(string `Failed to save user ${user.email} to database`, result);
        return result;
    }
    
    log:printInfo(string `User ${user.name} successfully saved to database with ID: ${user.id}`);
    return;
}

# Save lawyer profile to database using connection module
public function saveLawyerProfileToDatabase(User lawyer) returns error? {
    if lawyer.role != "lawyer" {
        return error("User is not a lawyer");
    }
    
    log:printInfo(string `Saving lawyer profile to database: ${lawyer.email}`);
    
    // Use the connection module's insertLawyerProfile function
    var result = insertLawyerProfile(lawyer.id, lawyer?.licenseNumber ?: "", lawyer?.specialty ?: "");
    if result is error {
        log:printError(string `Failed to save lawyer profile for ${lawyer.email}`, result);
        return result;
    }
    
    log:printInfo(string `Lawyer profile for ${lawyer.name} successfully saved to database`);
    return;
}
