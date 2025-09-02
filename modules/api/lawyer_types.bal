// Lawyer service type definitions

// Basic lawyer search result
public type LawyerSearchResult record {|
    int id;
    string name;
    string email;
    string specialty;
    float rating;
    int review_count;
    decimal hourly_rate;
|};

// Lawyer review
public type LawyerReview record {|
    int id;
    int rating;
    string review_text;
    string created_at;
    string reviewer_name;
|};

// Lawyer availability slot
public type AvailabilitySlot record {|
    string day;
    string[] slots;
|};

// Complete lawyer profile
public type LawyerFullProfile record {|
    int id;
    string name;
    string email;
    string phone;
    string specialty;
    string license_number;
    float rating;
    int review_count;
    decimal hourly_rate;
    LawyerReview[] reviews = [];
    AvailabilitySlot[] availability = [];
|};
