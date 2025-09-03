/*
 * DateTime Helper for Fedora System Backup Tool
 * Provides compatibility methods for DateTime operations
 */

using GLib;

public class DateTimeHelper : GLib.Object {
    
    /**
     * Converts DateTime to ISO8601 string format
     */
    public static string to_iso8601(DateTime dt) {
        return dt.format("%Y-%m-%dT%H:%M:%S%z");
    }
    
    /**
     * Creates DateTime from ISO8601 string
     */
    public static DateTime? from_iso8601(string iso_string) {
        try {
            // Simple parsing for basic ISO format
            var parts = iso_string.split("T");
            if (parts.length >= 2) {
                var date_parts = parts[0].split("-");
                var time_parts = parts[1].split(":");
                
                if (date_parts.length >= 3 && time_parts.length >= 2) {
                    int year = safe_parse_int(date_parts[0], 1970);
                    int month = safe_parse_int(date_parts[1], 1);
                    int day = safe_parse_int(date_parts[2], 1);
                    int hour = safe_parse_int(time_parts[0], 0);
                    int minute = safe_parse_int(time_parts[1], 0);
                    int second = 0;
                    
                    if (time_parts.length >= 3) {
                        var sec_part = time_parts[2].split("+")[0].split("-")[0];
                        second = safe_parse_int(sec_part, 0);
                    }
                    
                    // Validate ranges
                    if (year < 1970 || year > 3000 || month < 1 || month > 12 || 
                        day < 1 || day > 31 || hour < 0 || hour > 23 || 
                        minute < 0 || minute > 59 || second < 0 || second > 59) {
                        return null;
                    }
                    
                    return new DateTime.local(year, month, day, hour, minute, second);
                }
            }
        } catch (Error e) {
            // Return null on parsing error
        }
        
        return null;
    }
    
    /**
     * Safe integer parsing with validation
     */
    private static int safe_parse_int(string str, int default_value) {
        if (str == null || str.strip() == "") {
            return default_value;
        }
        
        var trimmed = str.strip();
        
        // Check if string contains only digits (and optional minus sign)
        bool valid = true;
        for (int i = 0; i < trimmed.length; i++) {
            char c = trimmed[i];
            if (i == 0 && c == '-') {
                continue; // Allow minus sign at start
            }
            if (!c.isdigit()) {
                valid = false;
                break;
            }
        }
        
        if (!valid || trimmed.length > 10) { // Prevent overflow
            return default_value;
        }
        
        int64 result = 0;
        int64 multiplier = 1;
        bool negative = false;
        
        if (trimmed[0] == '-') {
            negative = true;
            trimmed = trimmed.substring(1);
        }
        
        for (int i = trimmed.length - 1; i >= 0; i--) {
            int digit = trimmed[i] - '0';
            result += digit * multiplier;
            multiplier *= 10;
            
            // Check for overflow
            if (result > int.MAX || result < int.MIN) {
                return default_value;
            }
        }
        
        if (negative) {
            result = -result;
        }
        
        return (int)result;
    }
    
    /**
     * Gets system information
     */
    public static string get_system_info() {
        try {
            string stdout;
            Process.spawn_command_line_sync("uname -a", out stdout);
            return stdout.strip();
        } catch (Error e) {
            return "Unknown system";
        }
    }
}