import ballerina/sql;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerina/log;

# Database connection configuration
type DatabaseConfig record {|
    string host;
    int port;
    string database;
    string username;
    string password;
|};

# Get database configuration
public function getDatabaseConfig() returns DatabaseConfig {
    return {
        host: "localhost",
        port: 5433,
        database: "lexhub",
        username: "lexhub_user",
        password: "lexhub_password"
    };
}

# Create database connection
public function createConnection() returns postgresql:Client|sql:Error {
    DatabaseConfig config = getDatabaseConfig();
    
    postgresql:Client dbClient = check new (
        host = config.host,
        port = config.port,
        database = config.database,
        username = config.username,
        password = config.password
    );
    
    log:printInfo("Database connection established successfully");
    return dbClient;
}

# Insert user into database
public function insertUser(string email, string passwordHash, string name, string role, string? phone = ()) returns sql:ExecutionResult|sql:Error {
    postgresql:Client dbClient = check createConnection();
    
    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO users (email, password_hash, name, role, phone, verified, created_at, updated_at)
        VALUES (${email}, ${passwordHash}, ${name}, ${role}, ${phone}, false, NOW(), NOW())
        ON CONFLICT (email) DO UPDATE SET
            name = EXCLUDED.name,
            phone = EXCLUDED.phone,
            updated_at = NOW()
    `);
    
    check dbClient.close();
    return result;
}

# Insert lawyer profile
public function insertLawyerProfile(string userId, string licenseNumber, string specialty) returns sql:ExecutionResult|sql:Error {
    postgresql:Client dbClient = check createConnection();
    
    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO lawyer_profiles (user_id, license_number, specialty, verification_status, bio, hourly_rate)
        VALUES (${userId}, ${licenseNumber}, ${specialty}, 'pending', NULL, NULL)
    `);
    
    check dbClient.close();
    return result;
}

# Get all users
public function getAllUsers() returns json|sql:Error {
    postgresql:Client dbClient = check createConnection();
    
    sql:ParameterizedQuery query = `SELECT id, email, name, role, phone, verified, created_at FROM users ORDER BY created_at DESC`;
    stream<record {}, sql:Error?> resultStream = dbClient->query(query);
    
    json[] users = [];
    check from record {} user in resultStream
        do {
            users.push(user.toJson());
        };
    
    check dbClient.close();
    return users;
}
