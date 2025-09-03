/*
 * Fedora System Backup Tool - Simple Database Manager
 * Simplified version that compiles without errors
 */

using GLib;
using Gtk;

public class DatabaseManager : GLib.Object {
    
    private string database_path;
    private Sqlite.Database? database;
    private Logger logger;
    
    public DatabaseManager() {
        database_path = "/var/lib/fedora_backup/backup_history.db";
        logger = new Logger("/var/log/fedora_backup.log");
        initialize_database();
    }
    
    private void initialize_database() {
        try {
            var db_dir = File.new_for_path(Path.get_dirname(database_path));
            if (!db_dir.query_exists()) {
                db_dir.make_directory_with_parents();
            }
            
            int result = Sqlite.Database.open_v2(database_path, out database, Sqlite.OPEN_READWRITE | Sqlite.OPEN_CREATE);
            
            if (result != Sqlite.OK) {
                logger.log(LogLevel.ERROR, "Błąd otwarcia bazy danych: " + database_path);
                return;
            }
            
            database.exec("PRAGMA foreign_keys = ON");
            create_tables();
            logger.log(LogLevel.INFO, "Baza danych zainicjalizowana pomyślnie: " + database_path);
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd inicjalizacji bazy danych: " + e.message);
        }
    }
    
    private void create_tables() {
        try {
            var create_backups_table = """
                CREATE TABLE IF NOT EXISTS backups (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    backup_name TEXT NOT NULL,
                    backup_path TEXT NOT NULL UNIQUE,
                    creation_date TEXT NOT NULL,
                    fedora_version TEXT,
                    kernel_version TEXT,
                    backup_size INTEGER,
                    status TEXT DEFAULT 'completed',
                    error_message TEXT,
                    config TEXT,
                    custom_directories TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """;
            
            database.exec(create_backups_table);
            logger.log(LogLevel.INFO, "Tabele bazy danych utworzone pomyślnie");
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd tworzenia tabel: " + e.message);
        }
    }
    
    public bool add_backup_record(string backup_name, string backup_path, string fedora_version, string kernel_version, int64 backup_size, string config_json, string custom_dirs_json) {
        try {
            var insert_sql = """
                INSERT INTO backups (backup_name, backup_path, creation_date, fedora_version, kernel_version, backup_size, config, custom_directories)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """;
            
            Sqlite.Statement stmt;
            database.prepare_v2(insert_sql, -1, out stmt);
            
            stmt.bind_text(1, backup_name);
            stmt.bind_text(2, backup_path);
            stmt.bind_text(3, DateTimeHelper.to_iso8601(new DateTime.now_local()));
            stmt.bind_text(4, fedora_version);
            stmt.bind_text(5, kernel_version);
            stmt.bind_int64(6, backup_size);
            stmt.bind_text(7, config_json);
            stmt.bind_text(8, custom_dirs_json);
            
            int result = stmt.step();
            
            if (result == Sqlite.DONE) {
                logger.log(LogLevel.INFO, "Dodano rekord backupu: " + backup_name);
                return true;
            } else {
                logger.log(LogLevel.ERROR, "Błąd dodawania rekordu backupu");
                return false;
            }
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas dodawania rekordu backupu: " + e.message);
            return false;
        }
    }
    
    public List<BackupRecord> get_backup_history(int limit = 100) {
        var backups = new List<BackupRecord>();
        
        try {
            var select_sql = """
                SELECT id, backup_name, backup_path, creation_date, fedora_version, kernel_version, backup_size, status, error_message, config, custom_directories
                FROM backups
                ORDER BY creation_date DESC
                LIMIT ?
            """;
            
            Sqlite.Statement stmt;
            database.prepare_v2(select_sql, -1, out stmt);
            stmt.bind_int(1, limit);
            
            while (stmt.step() == Sqlite.ROW) {
                var record = new BackupRecord();
                record.id = stmt.column_int(0);
                record.backup_name = stmt.column_text(1);
                record.backup_path = stmt.column_text(2);
                record.creation_date = stmt.column_text(3);
                record.fedora_version = stmt.column_text(4);
                record.kernel_version = stmt.column_text(5);
                record.backup_size = stmt.column_int64(6);
                record.status = stmt.column_text(7);
                record.error_message = stmt.column_text(8);
                record.config = stmt.column_text(9);
                record.custom_directories = stmt.column_text(10);
                
                backups.append(record);
            }
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas pobierania historii backupów: " + e.message);
        }
        
        return backups;
    }
    
    public void close() {
        try {
            if (database != null) {
                // SQLite database will be closed automatically when object is destroyed
                database = null;
                logger.log(LogLevel.INFO, "Połączenie z bazą danych zamknięte");
            }
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas zamykania bazy danych: " + e.message);
        }
    }
}

public class BackupRecord : GLib.Object {
    public int id { get; set; default = 0; }
    public string backup_name { get; set; default = ""; }
    public string backup_path { get; set; default = ""; }
    public string creation_date { get; set; default = ""; }
    public string fedora_version { get; set; default = ""; }
    public string kernel_version { get; set; default = ""; }
    public int64 backup_size { get; set; default = 0; }
    public string status { get; set; default = ""; }
    public string error_message { get; set; default = ""; }
    public string config { get; set; default = ""; }
    public string custom_directories { get; set; default = ""; }
}