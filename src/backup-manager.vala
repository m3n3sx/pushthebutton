/*
 * Fedora System Backup Tool - Menedżer backupu
 * Autor: System Backup Tool
 * Wersja: 1.0.0
 * 
 * Klasa zarządzająca wszystkimi operacjami backupu systemu Fedora
 */

using GLib;
using Gtk;

public class BackupManager : GLib.Object {
    
    // Konfiguracja backupu
    public BackupConfig config { get; set; }
    
    // Lista wybranych katalogów do backupu
    private List<string> _custom_directories;
    
    // Ścieżka bazowa do backupów
    public string backup_base_path { get; private set; }
    
    // Logger
    private Logger logger;
    
    /**
     * Konstruktor menedżera backupu
     */
    public BackupManager() {
        // Inicjalizacja konfiguracji
        config = new BackupConfig();
        
        // Inicjalizacja listy katalogów
        _custom_directories = new List<string>();
        
        // Ustawienie ścieżki bazowej
        backup_base_path = "/var/backup/fedora_system";
        
        // Inicjalizacja loggera
        logger = new Logger("/var/log/fedora_backup.log");
        
        // Tworzenie katalogu bazowego
        create_backup_directory();
        
        // Ładowanie konfiguracji
        load_config();
    }
    
    /**
     * Tworzy katalog bazowy dla backupów
     */
    private void create_backup_directory() {
        try {
            var dir = File.new_for_path(backup_base_path);
            if (!dir.query_exists()) {
                dir.make_directory_with_parents();
                logger.log(LogLevel.INFO, "Utworzono katalog bazowy: " + backup_base_path);
            }
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd tworzenia katalogu bazowego: " + e.message);
        }
    }
    
    /**
     * Ładuje konfigurację z pliku
     */
    private void load_config() {
        try {
            var config_file = File.new_for_path("/etc/fedora_backup/backup_config.json");
            if (config_file.query_exists()) {
                config.load_from_file(config_file);
                logger.log(LogLevel.INFO, "Załadowano konfigurację backupu");
            } else {
                save_config();
                logger.log(LogLevel.INFO, "Utworzono domyślną konfigurację backupu");
            }
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd ładowania konfiguracji: " + e.message);
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
            
            var config_file = File.new_for_path("/etc/fedora_backup/backup_config.json");
            config.save_to_file(config_file);
            logger.log(LogLevel.INFO, "Zapisano konfigurację backupu");
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd zapisywania konfiguracji: " + e.message);
        }
    }
    
    /**
     * Dodaje katalog do listy backupowanych folderów
     */
    public bool add_custom_directory(string directory_path) {
        try {
            var path = File.new_for_path(directory_path);
            if (path.query_exists() && path.query_file_type(0) == FileType.DIRECTORY) {
                bool found = false;
                foreach (var dir in _custom_directories) {
                    if (dir == directory_path) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    _custom_directories.append(directory_path);
                    logger.log(LogLevel.INFO, "Dodano katalog do backupu: " + directory_path);
                    return true;
                } else {
                    logger.log(LogLevel.WARNING, "Katalog już jest na liście: " + directory_path);
                    return false;
                }
            } else {
                logger.log(LogLevel.ERROR, "Nieprawidłowa ścieżka katalogu: " + directory_path);
                return false;
            }
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas dodawania katalogu: " + e.message);
            return false;
        }
    }
    
    /**
     * Usuwa katalog z listy backupowanych folderów
     */
    public bool remove_custom_directory(string directory_path) {
        try {
            bool found = false;
            foreach (var dir in _custom_directories) {
                if (dir == directory_path) {
                    _custom_directories.remove(dir);
                    found = true;
                    break;
                }
            }
            if (found) {
                logger.log(LogLevel.INFO, "Usunięto katalog z backupu: " + directory_path);
                return true;
            } else {
                logger.log(LogLevel.WARNING, "Katalog nie jest na liście: " + directory_path);
                return false;
            }
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas usuwania katalogu: " + e.message);
            return false;
        }
    }
    
    /**
     * Zwraca listę wybranych katalogów do backupu
     */
    public List<string> get_custom_directories() {
        var result = new List<string>();
        foreach (var dir in _custom_directories) {
            result.append(dir);
        }
        return result;
    }
    
    /**
     * Tworzy backup zainstalowanych pakietów DNF i Flatpak
     */
    public bool backup_packages(string backup_path) {
        try {
            logger.log(LogLevel.INFO, "Rozpoczęcie backupu pakietów...");
            
            var packages_path = Path.build_filename(backup_path, "packages");
            var packages_dir = File.new_for_path(packages_path);
            if (!packages_dir.query_exists()) {
                packages_dir.make_directory_with_parents();
            }
            
            // Backup listy pakietów DNF
            var dnf_list_path = Path.build_filename(packages_path, "dnf_installed.txt");
            var dnf_list_file = File.new_for_path(dnf_list_path);
            
            // Wykonanie komendy dnf list installed
            string stdout, stderr;
            int exit_status;
            Process.spawn_sync(
                packages_path,
                {"dnf", "list", "installed"},
                null,
                SpawnFlags.SEARCH_PATH,
                null,
                out stdout,
                out stderr,
                out exit_status
            );
            
            if (exit_status == 0) {
                var output_stream = dnf_list_file.create(FileCreateFlags.NONE);
                var data_output_stream = new DataOutputStream(output_stream);
                data_output_stream.put_string(stdout);
                data_output_stream.close();
                logger.log(LogLevel.INFO, "Backup listy pakietów DNF zakończony");
            } else {
                logger.log(LogLevel.ERROR, "Błąd podczas pobierania listy pakietów DNF");
                return false;
            }
            
            // Backup repozytoriów DNF
            var dnf_repos_path = Path.build_filename(packages_path, "dnf_repos.txt");
            var dnf_repos_file = File.new_for_path(dnf_repos_path);
            
            Process.spawn_sync(
                packages_path,
                {"dnf", "repolist", "--enabled"},
                null,
                SpawnFlags.SEARCH_PATH,
                null,
                out stdout,
                out stderr,
                out exit_status
            );
            
            if (exit_status == 0) {
                var output_stream = dnf_repos_file.create(FileCreateFlags.NONE);
                var data_output_stream = new DataOutputStream(output_stream);
                data_output_stream.put_string(stdout);
                data_output_stream.close();
                logger.log(LogLevel.INFO, "Backup repozytoriów DNF zakończony");
            }
            
            // Backup pakietów Flatpak
            var flatpak_path = Path.build_filename(packages_path, "flatpak");
            var flatpak_dir = File.new_for_path(flatpak_path);
            if (!flatpak_dir.query_exists()) {
                flatpak_dir.make_directory();
            }
            
            // Lista zainstalowanych aplikacji Flatpak
            var flatpak_apps_path = Path.build_filename(flatpak_path, "flatpak_apps.txt");
            var flatpak_apps_file = File.new_for_path(flatpak_apps_path);
            
            Process.spawn_sync(
                flatpak_path,
                {"flatpak", "list", "--app"},
                null,
                SpawnFlags.SEARCH_PATH,
                null,
                out stdout,
                out stderr,
                out exit_status
            );
            
            if (exit_status == 0) {
                var output_stream = flatpak_apps_file.create(FileCreateFlags.NONE);
                var data_output_stream = new DataOutputStream(output_stream);
                data_output_stream.put_string(stdout);
                data_output_stream.close();
                logger.log(LogLevel.INFO, "Backup aplikacji Flatpak zakończony");
            }
            
            // Backup ustawień dconf
            var dconf_path = Path.build_filename(packages_path, "dconf_settings.txt");
            var dconf_file = File.new_for_path(dconf_path);
            
            Process.spawn_sync(
                packages_path,
                {"dconf", "dump", "/"},
                null,
                SpawnFlags.SEARCH_PATH,
                null,
                out stdout,
                out stderr,
                out exit_status
            );
            
            if (exit_status == 0) {
                var output_stream = dconf_file.create(FileCreateFlags.NONE);
                var data_output_stream = new DataOutputStream(output_stream);
                data_output_stream.put_string(stdout);
                data_output_stream.close();
                logger.log(LogLevel.INFO, "Backup ustawień dconf zakończony");
            }
            
            logger.log(LogLevel.INFO, "Backup pakietów zakończony pomyślnie");
            return true;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas backupu pakietów: " + e.message);
            return false;
        }
    }
    
    /**
     * Tworzy backup kluczy SSH i historii bash
     */
    public bool backup_user_data(string backup_path) {
        try {
            logger.log(LogLevel.INFO, "Rozpoczęcie backupu danych użytkownika...");
            
            var user_data_path = Path.build_filename(backup_path, "user_data");
            var user_data_dir = File.new_for_path(user_data_path);
            if (!user_data_dir.query_exists()) {
                user_data_dir.make_directory();
            }
            
            var home_dir = Environment.get_home_dir();
            
            // Backup kluczy SSH
            var ssh_source = Path.build_filename(home_dir, ".ssh");
            var ssh_source_dir = File.new_for_path(ssh_source);
            if (ssh_source_dir.query_exists()) {
                var ssh_dest = Path.build_filename(user_data_path, "ssh");
                var ssh_dest_dir = File.new_for_path(ssh_dest);
                copy_directory_recursive(ssh_source_dir, ssh_dest_dir);
                logger.log(LogLevel.INFO, "Backup kluczy SSH zakończony");
            }
            
            // Backup historii bash
            var bash_history_source = Path.build_filename(home_dir, ".bash_history");
            var bash_history_file = File.new_for_path(bash_history_source);
            if (bash_history_file.query_exists()) {
                var bash_history_dest = Path.build_filename(user_data_path, "bash_history");
                var bash_history_dest_file = File.new_for_path(bash_history_dest);
                bash_history_file.copy(bash_history_dest_file, FileCopyFlags.OVERWRITE);
                logger.log(LogLevel.INFO, "Backup historii bash zakończony");
            }
            
            logger.log(LogLevel.INFO, "Backup danych użytkownika zakończony pomyślnie");
            return true;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas backupu danych użytkownika: " + e.message);
            return false;
        }
    }
    
    /**
     * Tworzy backup ustawień systemu (/etc, systemd)
     */
    public bool backup_system_config(string backup_path) {
        try {
            logger.log(LogLevel.INFO, "Rozpoczęcie backupu konfiguracji systemu...");
            
            var config_path = Path.build_filename(backup_path, "system_config");
            var config_dir = File.new_for_path(config_path);
            if (!config_dir.query_exists()) {
                config_dir.make_directory();
            }
            
            // Backup katalogu /etc (tylko ważne pliki)
            var etc_backup_path = Path.build_filename(config_path, "etc");
            var etc_backup_dir = File.new_for_path(etc_backup_path);
            if (!etc_backup_dir.query_exists()) {
                etc_backup_dir.make_directory();
            }
            
            // Lista ważnych plików konfiguracyjnych
            string[] important_files = {
                "/etc/hosts",
                "/etc/resolv.conf",
                "/etc/fstab",
                "/etc/passwd",
                "/etc/group",
                "/etc/shadow",
                "/etc/gshadow",
                "/etc/sudoers",
                "/etc/ssh/sshd_config",
                "/etc/networkmanager/NetworkManager.conf"
            };
            
            foreach (var file_path in important_files) {
                var source_file = File.new_for_path(file_path);
                if (source_file.query_exists()) {
                    try {
                        var dest_path = Path.build_filename(etc_backup_path, Path.get_basename(file_path));
                        var dest_file = File.new_for_path(dest_path);
                        source_file.copy(dest_file, FileCopyFlags.OVERWRITE);
                        logger.log(LogLevel.INFO, "Backup pliku: " + file_path);
                    } catch (Error e) {
                        logger.log(LogLevel.WARNING, "Błąd backupu pliku " + file_path + ": " + e.message);
                    }
                }
            }
            
            // Backup usług systemd
            var systemd_path = Path.build_filename(config_path, "systemd");
            var systemd_dir = File.new_for_path(systemd_path);
            if (!systemd_dir.query_exists()) {
                systemd_dir.make_directory();
            }
            
            // Lista usług systemd
            var services_path = Path.build_filename(systemd_path, "services.txt");
            var services_file = File.new_for_path(services_path);
            
            string stdout, stderr;
            int exit_status;
            Process.spawn_sync(
                systemd_path,
                {"systemctl", "list-unit-files", "--type=service"},
                null,
                SpawnFlags.SEARCH_PATH,
                null,
                out stdout,
                out stderr,
                out exit_status
            );
            
            if (exit_status == 0) {
                var output_stream = services_file.create(FileCreateFlags.NONE);
                var data_output_stream = new DataOutputStream(output_stream);
                data_output_stream.put_string(stdout);
                data_output_stream.close();
            }
            
            logger.log(LogLevel.INFO, "Backup konfiguracji systemu zakończony pomyślnie");
            return true;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas backupu konfiguracji systemu: " + e.message);
            return false;
        }
    }
    
    /**
     * Tworzy backup środowiska pulpitu, motywów, czcionek, ikon
     */
    public bool backup_desktop_environment(string backup_path) {
        try {
            logger.log(LogLevel.INFO, "Rozpoczęcie backupu środowiska pulpitu...");
            
            var desktop_path = Path.build_filename(backup_path, "desktop_environment");
            var desktop_dir = File.new_for_path(desktop_path);
            if (!desktop_dir.query_exists()) {
                desktop_dir.make_directory();
            }
            
            // Backup motywów GTK
            string[] theme_paths = {
                "/usr/share/themes",
                GLib.Environment.get_home_dir() + "/.themes"
            };
            
            foreach (var theme_path in theme_paths) {
                var source_dir = File.new_for_path(theme_path);
                if (source_dir.query_exists()) {
                    try {
                        var dest_path = Path.build_filename(desktop_path, "themes_" + Path.get_basename(theme_path));
                        var dest_dir = File.new_for_path(dest_path);
                        copy_directory_recursive(source_dir, dest_dir);
                        logger.log(LogLevel.INFO, "Backup motywów: " + theme_path);
                    } catch (Error e) {
                        logger.log(LogLevel.WARNING, "Błąd backupu motywów " + theme_path + ": " + e.message);
                    }
                }
            }
            
            // Backup ikon
            string[] icon_paths = {
                "/usr/share/icons",
                GLib.Environment.get_home_dir() + "/.icons"
            };
            
            foreach (var icon_path in icon_paths) {
                var source_dir = File.new_for_path(icon_path);
                if (source_dir.query_exists()) {
                    try {
                        var dest_path = Path.build_filename(desktop_path, "icons_" + Path.get_basename(icon_path));
                        var dest_dir = File.new_for_path(dest_path);
                        copy_directory_recursive(source_dir, dest_dir);
                        logger.log(LogLevel.INFO, "Backup ikon: " + icon_path);
                    } catch (Error e) {
                        logger.log(LogLevel.WARNING, "Błąd backupu ikon " + icon_path + ": " + e.message);
                    }
                }
            }
            
            // Backup czcionek
            string[] font_paths = {
                "/usr/share/fonts",
                GLib.Environment.get_home_dir() + "/.fonts",
                GLib.Environment.get_home_dir() + "/.local/share/fonts"
            };
            
            foreach (var font_path in font_paths) {
                var source_dir = File.new_for_path(font_path);
                if (source_dir.query_exists()) {
                    try {
                        var dest_path = Path.build_filename(desktop_path, "fonts_" + Path.get_basename(font_path));
                        var dest_dir = File.new_for_path(dest_path);
                        copy_directory_recursive(source_dir, dest_dir);
                        logger.log(LogLevel.INFO, "Backup czcionek: " + font_path);
                    } catch (Error e) {
                        logger.log(LogLevel.WARNING, "Błąd backupu czcionek " + font_path + ": " + e.message);
                    }
                }
            }
            
            logger.log(LogLevel.INFO, "Backup środowiska pulpitu zakończony pomyślnie");
            return true;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas backupu środowiska pulpitu: " + e.message);
            return false;
        }
    }
    
    /**
     * Tworzy backup wybranych przez użytkownika katalogów
     */
    public bool backup_custom_directories(string backup_path) {
        try {
            if (_custom_directories.length() == 0) {
                logger.log(LogLevel.INFO, "Brak wybranych katalogów do backupu");
                return true;
            }
            
            logger.log(LogLevel.INFO, "Rozpoczęcie backupu wybranych katalogów...");
            
            var custom_backup_path = Path.build_filename(backup_path, "custom_directories");
            var custom_backup_dir = File.new_for_path(custom_backup_path);
            if (!custom_backup_dir.query_exists()) {
                custom_backup_dir.make_directory();
            }
            
            foreach (var directory in _custom_directories) {
                try {
                    var dir_path = File.new_for_path(directory);
                    if (dir_path.query_exists() && dir_path.query_file_type(0) == FileType.DIRECTORY) {
                        // Tworzenie unikalnej nazwy dla backupu
                        var timestamp = new DateTime.now_local().format("%Y%m%d_%H%M%S");
                        var backup_name = Path.get_basename(directory) + "_" + timestamp;
                        var backup_dir_path = Path.build_filename(custom_backup_path, backup_name);
                        var backup_dir = File.new_for_path(backup_dir_path);
                        
                        // Backup katalogu z zachowaniem struktury
                        copy_directory_recursive(dir_path, backup_dir);
                        
                        // Zapisanie metadanych
                        var metadata_path = Path.build_filename(backup_dir_path, "backup_metadata.json");
                        var metadata_file = File.new_for_path(metadata_path);
                        
                        var metadata = new Json.Object();
                        metadata.set_string_member("original_path", directory);
                        metadata.set_string_member("backup_date", DateTimeHelper.to_iso8601(new DateTime.now_local()));
                        metadata.set_int_member("size", get_directory_size(directory));
                        
                        var generator = new Json.Generator();
                        generator.set_root(new Json.Node.alloc().init_object(metadata));
                        generator.to_file(metadata_file.get_path());
                        
                        logger.log(LogLevel.INFO, "Backup katalogu " + directory + " zakończony pomyślnie");
                    } else {
                        logger.log(LogLevel.WARNING, "Katalog nie istnieje: " + directory);
                    }
                } catch (Error e) {
                    logger.log(LogLevel.ERROR, "Błąd podczas backupu katalogu " + directory + ": " + e.message);
                    continue;
                }
            }
            
            logger.log(LogLevel.INFO, "Backup wybranych katalogów zakończony");
            return true;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas backupu wybranych katalogów: " + e.message);
            return false;
        }
    }
    
    /**
     * Oblicza rozmiar katalogu w bajtach
     */
    private int64 get_directory_size(string directory_path) {
        int64 total_size = 0;
        try {
            var dir = File.new_for_path(directory_path);
            var enumerator = dir.enumerate_children("standard::*", FileQueryInfoFlags.NONE);
            FileInfo info;
            while ((info = enumerator.next_file()) != null) {
                var child_path = Path.build_filename(directory_path, info.get_name());
                if (info.get_file_type() == FileType.REGULAR) {
                    total_size += info.get_size();
                } else if (info.get_file_type() == FileType.DIRECTORY) {
                    total_size += get_directory_size(child_path);
                }
            }
        } catch (Error e) {
            logger.log(LogLevel.WARNING, "Błąd podczas obliczania rozmiaru katalogu " + directory_path + ": " + e.message);
        }
        return total_size;
    }
    
    /**
     * Kopiuje katalog rekurencyjnie
     */
    private void copy_directory_recursive(File source, File dest) throws Error {
        if (!dest.query_exists()) {
            dest.make_directory();
        }
        
        var enumerator = source.enumerate_children("standard::*", FileQueryInfoFlags.NONE);
        FileInfo info;
        while ((info = enumerator.next_file()) != null) {
            var source_child = source.get_child(info.get_name());
            var dest_child = dest.get_child(info.get_name());
            
            if (info.get_file_type() == FileType.REGULAR) {
                source_child.copy(dest_child, FileCopyFlags.OVERWRITE);
            } else if (info.get_file_type() == FileType.DIRECTORY) {
                copy_directory_recursive(source_child, dest_child);
            }
        }
    }
    
    /**
     * Tworzy pełny backup systemu Fedora
     */
    public string? create_full_backup(string? backup_name_param = null, bool include_custom = true) {
        try {
            string backup_name;
            if (backup_name_param == null) {
                var timestamp = new DateTime.now_local().format("%Y%m%d_%H%M%S");
                backup_name = "fedora_backup_" + timestamp;
            } else {
                backup_name = backup_name_param;
            }
            
            var backup_path = Path.build_filename(backup_base_path, backup_name);
            var backup_dir = File.new_for_path(backup_path);
            if (!backup_dir.query_exists()) {
                backup_dir.make_directory();
            }
            
            logger.log(LogLevel.INFO, "Rozpoczęcie pełnego backupu: " + backup_name);
            
            // Backup pakietów
            if (config.backup_packages) {
                if (!backup_packages(backup_path)) {
                    logger.log(LogLevel.ERROR, "Błąd podczas backupu pakietów");
                }
            }
            
            // Backup konfiguracji systemu
            if (config.backup_system_config) {
                if (!backup_system_config(backup_path)) {
                    logger.log(LogLevel.ERROR, "Błąd podczas backupu konfiguracji systemu");
                }
            }
            
            // Backup środowiska pulpitu
            if (config.backup_desktop) {
                if (!backup_desktop_environment(backup_path)) {
                    logger.log(LogLevel.ERROR, "Błąd podczas backupu środowiska pulpitu");
                }
            }
            
            // Backup danych użytkownika
            if (config.backup_users) {
                if (!backup_user_data(backup_path)) {
                    logger.log(LogLevel.ERROR, "Błąd podczas backupu danych użytkownika");
                }
            }
            
            // Backup wybranych katalogów
            if (include_custom && config.backup_custom_dirs) {
                if (!backup_custom_directories(backup_path)) {
                    logger.log(LogLevel.ERROR, "Błąd podczas backupu wybranych katalogów");
                }
            }
            
            // Zapisanie metadanych backupu
            var metadata_path = Path.build_filename(backup_path, "backup_metadata.json");
            var metadata_file = File.new_for_path(metadata_path);
            
            var metadata = new Json.Object();
            metadata.set_string_member("backup_name", backup_name);
            metadata.set_string_member("creation_date", DateTimeHelper.to_iso8601(new DateTime.now_local()));
            metadata.set_string_member("fedora_version", get_fedora_version());
            metadata.set_string_member("kernel_version", get_kernel_version());
            
            // Konfiguracja
            var config_obj = new Json.Object();
            config_obj.set_boolean_member("backup_packages", config.backup_packages);
            config_obj.set_boolean_member("backup_system_config", config.backup_system_config);
            config_obj.set_boolean_member("backup_desktop", config.backup_desktop);
            config_obj.set_boolean_member("backup_custom_dirs", config.backup_custom_dirs);
            metadata.set_object_member("config", config_obj);
            
            // Lista katalogów
            var dirs_array = new Json.Array();
            foreach (var dir in _custom_directories) {
                dirs_array.add_string_element(dir);
            }
            metadata.set_array_member("custom_directories", dirs_array);
            
            var generator = new Json.Generator();
            generator.set_root(new Json.Node.alloc().init_object(metadata));
            generator.to_file(metadata_file.get_path());
            
            logger.log(LogLevel.INFO, "Pełny backup zakończony pomyślnie: " + backup_path);
            return backup_path;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas tworzenia pełnego backupu: " + e.message);
            return null;
        }
    }
    
    /**
     * Zwraca wersję Fedora
     */
    private string get_fedora_version() {
        try {
            var file = File.new_for_path("/etc/fedora-release");
            if (file.query_exists()) {
                var input_stream = file.read();
                var data_input_stream = new DataInputStream(input_stream);
                var line = data_input_stream.read_line();
                input_stream.close();
                return line != null ? line : "Unknown";
            }
        } catch (Error e) {
            // Ignoruj błędy
        }
        return "Unknown";
    }
    
    /**
     * Zwraca wersję kernela
     */
    private string get_kernel_version() {
        try {
            var system_info = DateTimeHelper.get_system_info();
            return system_info;
        } catch (Error e) {
            return "Unknown";
        }
    }
    
    /**
     * Zwraca informacje o backupie
     */
    public Json.Object? get_backup_info(string backup_path) {
        try {
            var metadata_file = File.new_for_path(Path.build_filename(backup_path, "backup_metadata.json"));
            if (metadata_file.query_exists()) {
                var parser = new Json.Parser();
                parser.load_from_file(metadata_file.get_path());
                var root = parser.get_root();
                if (root != null && root.get_node_type() == Json.NodeType.OBJECT) {
                    return root.get_object();
                }
            }
            return null;
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd odczytu metadanych backupu: " + e.message);
            return null;
        }
    }
}

/**
 * Klasa konfiguracji backupu
 */
public class BackupConfig : GLib.Object {
    public bool backup_packages { get; set; default = true; }
    public bool backup_system_config { get; set; default = true; }
    public bool backup_desktop { get; set; default = true; }
    public bool backup_drivers { get; set; default = true; }
    public bool backup_users { get; set; default = true; }
    public bool backup_custom_dirs { get; set; default = true; }
    
    /**
     * Ładuje konfigurację z pliku
     */
    public void load_from_file(File file) throws Error {
        var parser = new Json.Parser();
        parser.load_from_file(file.get_path());
        var root = parser.get_root();
        
        if (root != null && root.get_node_type() == Json.NodeType.OBJECT) {
            var obj = root.get_object();
            
            if (obj.has_member("backup_packages")) {
                backup_packages = obj.get_boolean_member("backup_packages");
            }
            if (obj.has_member("backup_system_config")) {
                backup_system_config = obj.get_boolean_member("backup_system_config");
            }
            if (obj.has_member("backup_desktop")) {
                backup_desktop = obj.get_boolean_member("backup_desktop");
            }
            if (obj.has_member("backup_drivers")) {
                backup_drivers = obj.get_boolean_member("backup_drivers");
            }
            if (obj.has_member("backup_users")) {
                backup_users = obj.get_boolean_member("backup_users");
            }
            if (obj.has_member("backup_custom_dirs")) {
                backup_custom_dirs = obj.get_boolean_member("backup_custom_dirs");
            }
        }
    }
    
    /**
     * Zapisuje konfigurację do pliku
     */
    public void save_to_file(File file) throws Error {
        var obj = new Json.Object();
        obj.set_boolean_member("backup_packages", backup_packages);
        obj.set_boolean_member("backup_system_config", backup_system_config);
        obj.set_boolean_member("backup_desktop", backup_desktop);
        obj.set_boolean_member("backup_drivers", backup_drivers);
        obj.set_boolean_member("backup_users", backup_users);
        obj.set_boolean_member("backup_custom_dirs", backup_custom_dirs);
        
        var generator = new Json.Generator();
        generator.set_root(new Json.Node.alloc().init_object(obj));
        generator.to_file(file.get_path());
    }
}


