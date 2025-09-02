// Authentication module types

// Credentials record for login
public type Credentials record {|
    string email;
    string password;
|};

// User authentication data record
public type UserAuthData record {|
    string name;
    int id;
    string email;
    string password;
    string user_type;
|};

// Forgot password request record
public type ForgotPassword record {|
    string email;
|};

public type User record {|
    string name;
    string email;
    string password?;
    string user_type;
|};

public type Lawyer record {|
    
    string name;
    string email;
    string password?;
    string phone;
    string license_number;
    string specialty;
   |};