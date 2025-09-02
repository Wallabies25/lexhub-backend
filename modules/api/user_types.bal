// Type definitions for user service

// Basic user profile information
public type UserProfile record {|
    int id;
    string name;
    string email;
    string user_type;
|};

// Detailed lawyer information
public type LawyerDetail record {|
    string phone;
    string license_number;
    string specialty;
|};

// Extended lawyer profile information with dummy fields
public type LawyerProfileDetail record {|
    string phone;
    string license_number;
    string specialty;
    int cases_handled; // Dummy field for demo
    string success_rate; // Dummy field for demo
|};

// Detailed user profile with optional lawyer details
public type UserProfileDetail record {|
    int id;
    string name;
    string email;
    string user_type;
    string joined_date; // Added field for display purposes
    string profile_picture; // Added field for profile UI
    LawyerProfileDetail? lawyer_details = (); // Only populated for lawyers
|};

// Profile update payload
public type UserProfileUpdate record {|
    string name;
    LawyerProfileUpdateDetail? lawyer_details = ();
|};

// Lawyer profile update fields
public type LawyerProfileUpdateDetail record {|
    string phone;
    string specialty;
|};
