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
                    int year = int.parse(date_parts[0]);
                    int month = int.parse(date_parts[1]);
                    int day = int.parse(date_parts[2]);
                    int hour = int.parse(time_parts[0]);
                    int minute = int.parse(time_parts[1]);
                    int second = 0;
                    
                    if (time_parts.length >= 3) {
                        second = int.parse(time_parts[2].split("+")[0].split("-")[0]);
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