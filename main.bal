import lexhub_backend.database_service as db;
import lexhub_backend.auth_service as auth;

import lexhub_backend.api as api;
import ballerina/io;


public function main() returns error? {
   check db:connectDatabase();
   check auth:startAuthService();
   // check api:startUserService(); // Removed: function does not exist
   // check api:startProfileService(); // Removed: function does not exist
   check api:startLawyerService();
   check api:startConsultationService();
   
   io:println("LexHub backend services started successfully");
}