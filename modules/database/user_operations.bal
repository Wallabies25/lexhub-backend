import ballerina/log;
import lexhub_backend.auth;

# Save user to database using connection module
public function saveUserToDatabase(auth:User user) returns error? {
    log:printInfo(string `Saving user to database: ${user.email}`);
    
    // Use the connection module's insertUser function
    var result = insertUser(user.email, "", user.name, user.role, user?.phone);
    if result is error {
        log:printError(string `Failed to save user ${user.email} to database`, result);
        return result;
    }
    
    log:printInfo(string `User ${user.name} successfully saved to database with ID: ${user.id}`);
    return;
}

# Save lawyer profile to database using connection module
public function saveLawyerProfileToDatabase(auth:User lawyer) returns error? {
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
