import ballerina/log;
import ballerina/time;
import ballerina/regex;

# Security utilities and middleware

# Rate limiting configuration
public type RateLimitConfig record {|
    int maxRequests;
    int windowMinutes;
|};

# Audit log entry
public type AuditLog record {|
    string id;
    string userId?;
    string action;
    string resourcePath;
    string ipAddress;
    string userAgent;
    time:Utc timestamp;
    boolean success;
    string? errorMessage?;
|};

# Input validation functions

# Validate SQL injection patterns
public function containsSqlInjection(string input) returns boolean {
    string[] sqlPatterns = [
        "(?i)(union|select|insert|update|delete|drop|create|alter|exec|execute)",
        "(?i)(script|javascript|vbscript)",
        "(?i)(<|>|&lt;|&gt;)",
        "(?i)(onload|onerror|onclick)",
        "'|(\\-\\-)|(;)|(\\|)|(\\*)"
    ];
    
    foreach string pattern in sqlPatterns {
        if regex:matches(input, pattern) {
            return true;
        }
    }
    return false;
}

# Validate XSS patterns
public function containsXss(string input) returns boolean {
    string[] xssPatterns = [
        "(?i)<script.*?>.*?</script>",
        "(?i)javascript:",
        "(?i)on(load|error|click|mouse|focus|blur|submit|reset)",
        "(?i)<iframe",
        "(?i)<object",
        "(?i)<embed"
    ];
    
    foreach string pattern in xssPatterns {
        if regex:matches(input, pattern) {
            return true;
        }
    }
    return false;
}

# Sanitize user input
public function sanitizeInput(string input) returns string {
    string sanitized = input;
    
    // Remove potential script tags
    sanitized = regex:replaceAll(sanitized, "(?i)<script.*?>.*?</script>", "");
    
    // Remove potential dangerous attributes
    sanitized = regex:replaceAll(sanitized, "(?i)on(load|error|click|mouse|focus|blur|submit|reset)\\s*=\\s*[\"'][^\"']*[\"']", "");
    
    // Remove javascript: protocol
    sanitized = regex:replaceAll(sanitized, "(?i)javascript:", "");
    
    return sanitized;
}

# Security headers for HTTP responses
public function getSecurityHeaders() returns map<string> {
    return {
        "X-Content-Type-Options": "nosniff",
        "X-Frame-Options": "DENY",
        "X-XSS-Protection": "1; mode=block",
        "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
        "Content-Security-Policy": "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"
    };
}

# Validate request origin for CORS
public function validateOrigin(string origin) returns boolean {
    string[] allowedOrigins = [
        "https://lexhub-frontend.vercel.app",
        "https://localhost:3000",
        "http://localhost:3000",
        "https://lexhub.lk"
    ];
    
    foreach string allowedOrigin in allowedOrigins {
        if origin == allowedOrigin {
            return true;
        }
    }
    return false;
}

# Create audit log entry
public function createAuditLog(string action, string resourcePath, string? userId, 
                             string ipAddress, string userAgent, boolean success, 
                             string? errorMessage) returns AuditLog {
    return {
        id: "audit_" + time:utcNow().toString(),
        userId: userId,
        action: action,
        resourcePath: resourcePath,
        ipAddress: ipAddress,
        userAgent: userAgent,
        timestamp: time:utcNow(),
        success: success,
        errorMessage: errorMessage
    };
}

# Log security event
public function logSecurityEvent(AuditLog auditLog) {
    string userIdStr = auditLog?.userId ?: "anonymous";
    string errorMsg = auditLog?.errorMessage ?: "Unknown error";
    
    if auditLog.success {
        log:printInfo(string `Security audit: ${auditLog.action} on ${auditLog.resourcePath} by user ${userIdStr} from ${auditLog.ipAddress}`);
    } else {
        log:printWarn(string `Security audit: Failed ${auditLog.action} on ${auditLog.resourcePath} by user ${userIdStr} from ${auditLog.ipAddress} - ${errorMsg}`);
    }
}

# Validate IP address format
public function isValidIpAddress(string ip) returns boolean {
    string ipv4Pattern = "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$";
    string ipv6Pattern = "^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$";
    
    return regex:matches(ip, ipv4Pattern) || regex:matches(ip, ipv6Pattern);
}

# Check if request is from suspicious source
public function isSuspiciousRequest(string ipAddress, string userAgent) returns boolean {
    // Check for common bot patterns
    string[] suspiciousAgents = [
        "(?i)bot",
        "(?i)crawler",
        "(?i)spider",
        "(?i)scraper"
    ];
    
    foreach string pattern in suspiciousAgents {
        if regex:matches(userAgent, pattern) {
            return true;
        }
    }
    
    // Check for private/local IP ranges (might be suspicious in production)
    string[] privateRanges = [
        "^192\\.168\\.",
        "^10\\.",
        "^172\\.(1[6-9]|2[0-9]|3[0-1])\\."
    ];
    
    foreach string pattern in privateRanges {
        if regex:matches(ipAddress, pattern) {
            return true;
        }
    }
    
    return false;
}
