// Consultation types definition

// Booking request payload
public type ConsultationBooking record {|
    int lawyer_id;
    string date;
    string time;
    string topic;
    string? notes;
|};

// Consultation detail record
public type ConsultationDetail record {|
    int id;
    int lawyer_id;
    string consultation_date;
    string consultation_time;
    string topic;
    string status;
    string? notes;
    string created_at;
    string lawyer_name;
|};

// Lawyer's view of consultation
public type LawyerConsultationView record {|
    int id;
    int client_id;
    string consultation_date;
    string consultation_time;
    string topic;
    string status;
    string? notes;
    string created_at;
    string client_name;
|};

// Status update request
public type ConsultationStatusUpdate record {|
    string status; // "pending", "accepted", "rejected", "completed", "cancelled"
    string? notes;
|};

// Review submission
public type ConsultationReview record {|
    int rating; // 1-5 stars
    string review_text;
|};
