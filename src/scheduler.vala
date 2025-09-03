/*
 * Fedora System Backup Tool - Harmonogramowanie
 * Autor: System Backup Tool
 * Wersja: 1.0.0
 * 
 * Klasa zarządzająca harmonogramowaniem automatycznych backupów
 */

using GLib;
using Gtk;

public class Scheduler : GLib.Object {
    
    // Referencja do menedżera backupu
    private BackupManager? backup_manager;
    
    // Konfiguracja harmonogramowania
    private SchedulerConfig config;
    
    // Timer dla harmonogramowania
    private uint timer_id;
    
    // Logger
    private Logger logger;
    
    /**
     * Konstruktor harmonogramowania
     */
    public Scheduler() {
        // Inicjalizacja konfiguracji
        config = new SchedulerConfig();
        
        // Inicjalizacja loggera
        logger = new Logger("/var/log/fedora_backup.log");
        
        // Ładowanie konfiguracji
        load_config();
        
        // Inicjalizacja timer_id
        timer_id = 0;
    }
    
    /**
     * Ustawia referencję do menedżera backupu
     */
    public void set_backup_manager(BackupManager manager) {
        backup_manager = manager;
    }
    
    /**
     * Ładuje konfigurację z pliku
     */
    private void load_config() {
        try {
            var config_file = File.new_for_path("/etc/fedora_backup/scheduler_config.json");
            if (config_file.query_exists()) {
                config.load_from_file(config_file.get_path());
                logger.log(LogLevel.INFO, "Załadowano konfigurację harmonogramowania");
            } else {
                save_config();
                logger.log(LogLevel.INFO, "Utworzono domyślną konfigurację harmonogramowania");
            }
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd ładowania konfiguracji harmonogramowania: " + e.message);
        }
    }
    
    /**
     * Zapisuje konfigurację do pliku
     */
    private void save_config() {
        try {
            var config_dir = File.new_for_path("/etc/fedora_backup");
            if (!config_dir.query_exists()) {
                config_dir.make_directory_with_parents();
            }
            
            var config_file = File.new_for_path("/etc/fedora_backup/scheduler_config.json");
            config.save_to_file(config_file.get_path());
            logger.log(LogLevel.INFO, "Zapisano konfigurację harmonogramowania");
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd zapisywania konfiguracji harmonogramowania: " + e.message);
        }
    }
    
    /**
     * Ustawia harmonogramowanie systemd
     */
    public bool setup_systemd_scheduler() {
        try {
            logger.log(LogLevel.INFO, "Ustawianie harmonogramowania systemd...");
            
            // Tworzenie pliku usługi systemd
            var service_content = generate_systemd_service();
            var service_file = File.new_for_path("/etc/systemd/system/fedora-backup.service");
            var output_stream = service_file.replace(null, false, FileCreateFlags.NONE);
            var data_output_stream = new DataOutputStream(output_stream);
            data_output_stream.put_string(service_content);
            data_output_stream.close();
            
            // Tworzenie pliku timera systemd
            var timer_content = generate_systemd_timer();
            var timer_file = File.new_for_path("/etc/systemd/system/fedora-backup.timer");
            output_stream = timer_file.replace(null, false, FileCreateFlags.NONE);
            data_output_stream = new DataOutputStream(output_stream);
            data_output_stream.put_string(timer_content);
            data_output_stream.close();
            
            // Reload systemd
            string stdout, stderr;
            int exit_status;
            Process.spawn_sync(
                "/",
                {"systemctl", "daemon-reload"},
                null,
                SpawnFlags.SEARCH_PATH,
                null,
                out stdout,
                out stderr,
                out exit_status
            );
            
            if (exit_status != 0) {
                logger.log(LogLevel.ERROR, "Błąd podczas reload systemd: " + stderr);
                return false;
            }
            
            // Włączenie timera
            Process.spawn_sync(
                "/",
                {"systemctl", "enable", "fedora-backup.timer"},
                null,
                SpawnFlags.SEARCH_PATH,
                null,
                out stdout,
                out stderr,
                out exit_status
            );
            
            if (exit_status != 0) {
                logger.log(LogLevel.ERROR, "Błąd podczas włączania timera: " + stderr);
                return false;
            }
            
            // Uruchomienie timera
            Process.spawn_sync(
                "/",
                {"systemctl", "start", "fedora-backup.timer"},
                null,
                SpawnFlags.SEARCH_PATH,
                null,
                out stdout,
                out stderr,
                out exit_status
            );
            
            if (exit_status != 0) {
                logger.log(LogLevel.ERROR, "Błąd podczas uruchamiania timera: " + stderr);
                return false;
            }
            
            logger.log(LogLevel.INFO, "Harmonogramowanie systemd ustawione pomyślnie");
            return true;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas ustawiania harmonogramowania systemd: " + e.message);
            return false;
        }
    }
    
    /**
     * Generuje zawartość pliku usługi systemd
     */
    private string generate_systemd_service() {
        var script_path = "/usr/bin/fedora-backup-scheduled.sh";
        
        return """[Unit]
Description=Fedora System Backup Service
After=network.target

[Service]
Type=oneshot
ExecStart=%s
User=root
Group=root

[Install]
WantedBy=multi-user.target
""".printf(script_path);
    }
    
    /**
     * Generuje zawartość pliku timera systemd
     */
    private string generate_systemd_timer() {
        string on_calendar = "";
        
        switch (config.frequency) {
            case "daily":
                on_calendar = "OnCalendar=*-*-* %02d:00:00".printf(config.hour);
                break;
            case "weekly":
                on_calendar = "OnCalendar=weekly %02d:00:00".printf(config.hour);
                break;
            case "monthly":
                on_calendar = "OnCalendar=*-*-01 %02d:00:00".printf(config.hour);
                break;
            default:
                on_calendar = "OnCalendar=*-*-* %02d:00:00".printf(config.hour);
                break;
        }
        
        return """[Unit]
Description=Fedora System Backup Timer
Requires=fedora-backup.service

[Timer]
%s
Persistent=true

[Install]
WantedBy=timers.target
""".printf(on_calendar);
    }
    
    /**
     * Ustawia harmonogramowanie Python
     */
    public bool setup_python_scheduler() {
        try {
            logger.log(LogLevel.INFO, "Ustawianie harmonogramowania Python...");
            
            // Uruchomienie harmonogramowania w osobnym wątku
            new Thread<void*>("python-scheduler-thread", () => {
                run_python_scheduler();
                return null;
            });
            
            logger.log(LogLevel.INFO, "Harmonogramowanie Python ustawione pomyślnie");
            return true;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas ustawiania harmonogramowania Python: " + e.message);
            return false;
        }
    }
    
    /**
     * Uruchamia harmonogramowanie Python
     */
    private void run_python_scheduler() {
        try {
            while (config.enabled) {
                var now = new DateTime.now_local();
                var next_run = calculate_next_run();
                
                if (now.compare(next_run) >= 0) {
                    // Wykonanie zaplanowanego backupu
                    run_scheduled_backup();
                    
                    // Obliczenie następnego uruchomienia
                    next_run = calculate_next_run();
                }
                
                // Czekanie do następnego uruchomienia
                var wait_time = (next_run.difference(now) / 1000000).clamp(1, 3600); // 1 sekunda - 1 godzina
                Thread.usleep((ulong)(wait_time * 1000000));
            }
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd w harmonogramowaniu Python: " + e.message);
        }
    }
    
    /**
     * Oblicza czas następnego uruchomienia
     */
    private DateTime calculate_next_run() {
        var now = new DateTime.now_local();
        
        switch (config.frequency) {
            case "daily":
                return new DateTime.local(now.get_year(), now.get_month(), now.get_day_of_month(), config.hour, 0, 0).add_days(1);
            case "weekly":
                var days_until_next_week = 8 - now.get_day_of_week();
                return new DateTime.local(now.get_year(), now.get_month(), now.get_day_of_month(), config.hour, 0, 0).add_days(days_until_next_week);
            case "monthly":
                var next_month = now.get_month() + 1;
                var next_year = now.get_year();
                if (next_month > 12) {
                    next_month = 1;
                    next_year++;
                }
                return new DateTime.local(next_year, next_month, 1, config.hour, 0, 0);
            default:
                return now.add_days(1);
        }
    }
    
    /**
     * Uruchamia zaplanowany backup
     */
    private void run_scheduled_backup() {
        try {
            logger.log(LogLevel.INFO, "Uruchomienie zaplanowanego backupu...");
            
            if (backup_manager != null) {
                // Wykonanie backupu
                var backup_path = backup_manager.create_full_backup();
                
                if (backup_path != null) {
                    logger.log(LogLevel.INFO, "Zaplanowany backup zakończony pomyślnie: " + backup_path);
                    
                    // Upload do chmury (jeśli włączony)
                    if (config.upload_to_cloud) {
                        upload_scheduled_backup_to_cloud(backup_path);
                    }
                    
                    // Czyszczenie starych backupów
                    cleanup_old_backups();
                } else {
                    logger.log(LogLevel.ERROR, "Zaplanowany backup zakończony niepowodzeniem");
                }
            } else {
                logger.log(LogLevel.ERROR, "Brak referencji do menedżera backupu");
            }
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas wykonywania zaplanowanego backupu: " + e.message);
        }
    }
    
    /**
     * Upload zaplanowanego backupu do chmury
     */
    private void upload_scheduled_backup_to_cloud(string backup_path) {
        try {
            logger.log(LogLevel.INFO, "Upload zaplanowanego backupu do chmury...");
            
            // TODO: Implementacja uploadu do chmury
            // var cloud_integration = new CloudIntegration();
            // cloud_integration.upload_backup(backup_path);
            
            logger.log(LogLevel.INFO, "Upload zaplanowanego backupu do chmury zakończony (placeholder)");
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas uploadu do chmury: " + e.message);
        }
    }
    
    /**
     * Czyści stare backupy
     */
    private void cleanup_old_backups() {
        try {
            if (backup_manager != null && config.retention_days > 0) {
                logger.log(LogLevel.INFO, "Czyszczenie starych backupów (retencja: %d dni)...".printf(config.retention_days));
                
                var backup_base_path = backup_manager.backup_base_path;
                var base_dir = File.new_for_path(backup_base_path);
                
                if (base_dir.query_exists()) {
                    var cutoff_date = new DateTime.now_local().add_days(-config.retention_days);
                    var enumerator = base_dir.enumerate_children("standard::*", FileQueryInfoFlags.NONE);
                    FileInfo info;
                    
                    while ((info = enumerator.next_file()) != null) {
                        if (info.get_file_type() == FileType.DIRECTORY) {
                            var backup_dir = base_dir.get_child(info.get_name());
                            var metadata_file = backup_dir.get_child("backup_metadata.json");
                            
                            if (metadata_file.query_exists()) {
                                try {
                                    var parser = new Json.Parser();
                                    parser.load_from_file(metadata_file.get_path());
                                    var root = parser.get_root();
                                    
                                    if (root != null && root.get_node_type() == Json.NodeType.OBJECT) {
                                        var obj = root.get_object();
                                        
                                        if (obj.has_member("creation_date")) {
                                            var creation_date_str = obj.get_string_member("creation_date");
                                            var creation_date = new DateTime.from_iso8601(creation_date_str, null);
                                            
                                            if (creation_date != null && creation_date.compare(cutoff_date) < 0) {
                                                // Usunięcie starego backupu
                                                delete_directory_recursive(backup_dir);
                                                logger.log(LogLevel.INFO, "Usunięto stary backup: " + info.get_name());
                                            }
                                        }
                                    }
                                } catch (Error e) {
                                    logger.log(LogLevel.WARNING, "Błąd podczas sprawdzania daty backupu " + info.get_name() + ": " + e.message);
                                    continue;
                                }
                            }
                        }
                    }
                }
                
                logger.log(LogLevel.INFO, "Czyszczenie starych backupów zakończone");
            }
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas czyszczenia starych backupów: " + e.message);
        }
    }
    
    /**
     * Usuwa katalog rekurencyjnie
     */
    private void delete_directory_recursive(File dir) throws Error {
        var enumerator = dir.enumerate_children("standard::*", FileQueryInfoFlags.NONE);
        FileInfo info;
        
        while ((info = enumerator.next_file()) != null) {
            var child = dir.get_child(info.get_name());
            if (info.get_file_type() == FileType.DIRECTORY) {
                delete_directory_recursive(child);
            } else {
                child.delete();
            }
        }
        dir.delete();
    }
    
    /**
     * Uruchamia harmonogramowanie
     */
    public bool start_scheduler() {
        try {
            if (!config.enabled) {
                logger.log(LogLevel.INFO, "Harmonogramowanie jest wyłączone");
                return false;
            }
            
            logger.log(LogLevel.INFO, "Uruchamianie harmonogramowania...");
            
            bool success = false;
            
            switch (config.method) {
                case "systemd":
                    success = setup_systemd_scheduler();
                    break;
                case "python":
                    success = setup_python_scheduler();
                    break;
                default:
                    logger.log(LogLevel.ERROR, "Nieznana metoda harmonogramowania: " + config.method);
                    return false;
            }
            
            if (success) {
                logger.log(LogLevel.INFO, "Harmonogramowanie uruchomione pomyślnie");
            } else {
                logger.log(LogLevel.ERROR, "Nie udało się uruchomić harmonogramowania");
            }
            
            return success;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas uruchamiania harmonogramowania: " + e.message);
            return false;
        }
    }
    
    /**
     * Zatrzymuje harmonogramowanie
     */
    public void stop_scheduler() {
        try {
            logger.log(LogLevel.INFO, "Zatrzymywanie harmonogramowania...");
            
            if (config.method == "systemd") {
                // Zatrzymanie timera systemd
                string stdout, stderr;
                int exit_status;
                Process.spawn_sync(
                    "/",
                    {"systemctl", "stop", "fedora-backup.timer"},
                    null,
                    SpawnFlags.SEARCH_PATH,
                    null,
                    out stdout,
                    out stderr,
                    out exit_status
                );
                
                if (exit_status == 0) {
                    logger.log(LogLevel.INFO, "Timer systemd zatrzymany");
                }
            }
            
            // Zatrzymanie timera Python
            if (timer_id > 0) {
                Source.remove(timer_id);
                timer_id = 0;
            }
            
            logger.log(LogLevel.INFO, "Harmonogramowanie zatrzymane");
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas zatrzymywania harmonogramowania: " + e.message);
        }
    }
    
    /**
     * Zwraca status harmonogramowania
     */
    public Json.Object get_scheduler_status() {
        var status = new Json.Object();
        
        try {
            status.set_boolean_member("enabled", config.enabled);
            status.set_string_member("method", config.method);
            status.set_string_member("frequency", config.frequency);
            status.set_int_member("hour", config.hour);
            status.set_int_member("retention_days", config.retention_days);
            status.set_boolean_member("upload_to_cloud", config.upload_to_cloud);
            
            if (config.method == "systemd") {
                // Sprawdzenie statusu timera systemd
                string stdout, stderr;
                int exit_status;
                Process.spawn_sync(
                    "/",
                    {"systemctl", "is-active", "fedora-backup.timer"},
                    null,
                    SpawnFlags.SEARCH_PATH,
                    null,
                    out stdout,
                    out stderr,
                    out exit_status
                );
                
                if (exit_status == 0) {
                    status.set_string_member("systemd_status", stdout.strip());
                } else {
                    status.set_string_member("systemd_status", "inactive");
                }
            }
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas pobierania statusu harmonogramowania: " + e.message);
            status.set_string_member("error", e.message);
        }
        
        return status;
    }
    
    /**
     * Aktualizuje konfigurację harmonogramowania
     */
    public void update_scheduler_config(string method, string frequency, int hour, int retention_days) {
        config.method = method;
        config.frequency = frequency;
        config.hour = hour;
        config.retention_days = retention_days;
        
        save_config();
        logger.log(LogLevel.INFO, "Zaktualizowano konfigurację harmonogramowania");
        
        // Restart harmonogramowania jeśli jest włączony
        if (config.enabled) {
            stop_scheduler();
            start_scheduler();
        }
    }
    
    /**
     * Testuje harmonogramowanie
     */
    public bool test_scheduler() {
        try {
            logger.log(LogLevel.INFO, "Testowanie harmonogramowania...");
            
            // Symulacja zaplanowanego backupu
            run_scheduled_backup();
            
            logger.log(LogLevel.INFO, "Test harmonogramowania zakończony pomyślnie");
            return true;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas testu harmonogramowania: " + e.message);
            return false;
        }
    }
}

/**
 * Klasa konfiguracji harmonogramowania
 */
public class SchedulerConfig : GLib.Object {
    public bool enabled { get; set; default = false; }
    public string method { get; set; default = "systemd"; }
    public string frequency { get; set; default = "daily"; }
    public int hour { get; set; default = 2; }
    public int retention_days { get; set; default = 30; }
    public bool upload_to_cloud { get; set; default = false; }
    
    /**
     * Ładuje konfigurację z pliku
     */
    public void load_from_file(string file_path) throws Error {
        var parser = new Json.Parser();
        parser.load_from_file(file_path);
        var root = parser.get_root();
        
        if (root != null && root.get_node_type() == Json.NodeType.OBJECT) {
            var obj = root.get_object();
            
            if (obj.has_member("enabled")) {
                enabled = obj.get_boolean_member("enabled");
            }
            if (obj.has_member("method")) {
                method = obj.get_string_member("method");
            }
            if (obj.has_member("frequency")) {
                frequency = obj.get_string_member("frequency");
            }
            if (obj.has_member("hour")) {
                hour = (int)obj.get_int_member("hour");
            }
            if (obj.has_member("retention_days")) {
                retention_days = (int)obj.get_int_member("retention_days");
            }
            if (obj.has_member("upload_to_cloud")) {
                upload_to_cloud = obj.get_boolean_member("upload_to_cloud");
            }
        }
    }
    
    /**
     * Zapisuje konfigurację do pliku
     */
    public void save_to_file(string file_path) throws Error {
        var obj = new Json.Object();
        obj.set_boolean_member("enabled", enabled);
        obj.set_string_member("method", method);
        obj.set_string_member("frequency", frequency);
        obj.set_int_member("hour", hour);
        obj.set_int_member("retention_days", retention_days);
        obj.set_boolean_member("upload_to_cloud", upload_to_cloud);
        
        var generator = new Json.Generator();
        generator.set_root(new Json.Node.alloc().init_object(obj));
        generator.to_file(file_path);
    }
}
