import ballerina/http;
import ballerina/io;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

configurable string USER = ?;
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable int PORT = ?;
configurable string DATABASE = ?;

public final mysql:Client dbClient = check new (
    host = HOST,
    user = USER,
    password = PASSWORD,
    port = PORT,
    database = DATABASE
);

public listener http:Listener mainListener = new (8080);

public function connectDatabase() returns error? {
    io:println("Database connected successfully...");
}
