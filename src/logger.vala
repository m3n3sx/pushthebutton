/*
 * Fedora System Backup Tool - Logger
 * Autor: System Backup Tool
 * Wersja: 1.0.0
 *
 * Klasa do logowania operacji aplikacji
 */

using GLib;

public enum LogLevel {
    DEBUG,
    INFO,
    WARNING,
    ERROR
}

public class Logger : GLib.Object {
    private string log_file_path;
    private bool console_output;
    
    public Logger(string? log_file = null, bool console = true) {
        log_file_path = log_file ?? "/var/log/fedora_backup.log";
        console_output = console;
    }
    
    public void log(LogLevel level, string message) {
        var timestamp = new DateTime.now_local().format("%Y-%m-%d %H:%M:%S");
        var level_str = level.to_string();
        var log_message = "%s - %s - %s\n".printf(timestamp, level_str, message);
        
        // Wyświetlenie w konsoli
        if (console_output) {
            switch (level) {
                case LogLevel.ERROR:
                    stderr.printf(log_message);
                    break;
                case LogLevel.WARNING:
                    stderr.printf(log_message);
                    break;
                default:
                    stdout.printf(log_message);
                    break;
            }
        }
        
        // Zapis do pliku
        try {
            var file = File.new_for_path(log_file_path);
            var parent = file.get_parent();
            if (parent != null && !parent.query_exists()) {
                parent.make_directory_with_parents();
            }
            
            var output_stream = file.append_to(FileCreateFlags.NONE);
            var data_output_stream = new DataOutputStream(output_stream);
            data_output_stream.put_string(log_message);
            data_output_stream.close();
        } catch (Error e) {
            // Jeśli nie można zapisać do pliku, wyświetl błąd w konsoli
            stderr.printf("Błąd zapisu do pliku log: %s\n", e.message);
        }
    }
    
    public void debug(string message) {
        log(LogLevel.DEBUG, message);
    }
    
    public void info(string message) {
        log(LogLevel.INFO, message);
    }
    
    public void warning(string message) {
        log(LogLevel.WARNING, message);
    }
    
    public void error(string message) {
        log(LogLevel.ERROR, message);
    }
}
