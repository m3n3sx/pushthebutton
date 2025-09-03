/*
 * Fedora System Backup Tool - Menedżer przywracania
 * Autor: System Backup Tool
 * Wersja: 1.0.0
 * 
 * Klasa zarządzająca przywracaniem systemu z backupu
 */

using GLib;
using Gtk;

public class RestoreManager : GLib.Object {
    
    // Logger
    private Logger logger;
    
    /**
     * Konstruktor menedżera przywracania
     */
    public RestoreManager() {
        // Inicjalizacja loggera
        logger = new Logger("/var/log/fedora_backup.log");
    }
    
    /**
     * Przywraca pakiety z backupu
     */
    public bool restore_packages(string backup_path) {
        try {
            logger.log(LogLevel.INFO, "Rozpoczęcie przywracania pakietów...");
            
            var packages_path = Path.build_filename(backup_path, "packages");
            var packages_dir = File.new_for_path(packages_path);
            
            if (!packages_dir.query_exists()) {
                logger.log(LogLevel.WARNING, "Katalog pakietów nie istnieje w backupie");
                return false;
            }
            
            // Przywracanie pakietów DNF
            var dnf_list_path = Path.build_filename(packages_path, "dnf_installed.txt");
            var dnf_list_file = File.new_for_path(dnf_list_path);
            
            if (dnf_list_file.query_exists()) {
                // TODO: Implementacja przywracania pakietów DNF
                logger.log(LogLevel.INFO, "Przywracanie pakietów DNF (placeholder)");
            }
            
            // Przywracanie aplikacji Flatpak
            var flatpak_path = Path.build_filename(packages_path, "flatpak");
            var flatpak_dir = File.new_for_path(flatpak_path);
            
            if (flatpak_dir.query_exists()) {
                // TODO: Implementacja przywracania aplikacji Flatpak
                logger.log(LogLevel.INFO, "Przywracanie aplikacji Flatpak (placeholder)");
            }
            
            logger.log(LogLevel.INFO, "Przywracanie pakietów zakończone");
            return true;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas przywracania pakietów: " + e.message);
            return false;
        }
    }
    
    /**
     * Przywraca konfigurację systemu z backupu
     */
    public bool restore_system_config(string backup_path) {
        try {
            logger.log(LogLevel.INFO, "Rozpoczęcie przywracania konfiguracji systemu...");
            
            var config_path = Path.build_filename(backup_path, "system_config");
            var config_dir = File.new_for_path(config_path);
            
            if (!config_dir.query_exists()) {
                logger.log(LogLevel.WARNING, "Katalog konfiguracji systemu nie istnieje w backupie");
                return false;
            }
            
            // Przywracanie plików /etc
            var etc_backup_path = Path.build_filename(config_path, "etc");
            var etc_backup_dir = File.new_for_path(etc_backup_path);
            
            if (etc_backup_dir.query_exists()) {
                var enumerator = etc_backup_dir.enumerate_children("standard::*", FileQueryInfoFlags.NONE);
                FileInfo info;
                
                while ((info = enumerator.next_file()) != null) {
                    var backup_file = etc_backup_dir.get_child(info.get_name());
                    var target_path = "/etc/" + info.get_name();
                    var target_file = File.new_for_path(target_path);
                    
                    try {
                        // Backup istniejącego pliku
                        if (target_file.query_exists()) {
                            var backup_path_old = target_path + ".backup";
                            var backup_file_old = File.new_for_path(backup_path_old);
                            target_file.move(backup_file_old, FileCopyFlags.OVERWRITE);
                            logger.log(LogLevel.INFO, "Utworzono backup istniejącego pliku: " + target_path);
                        }
                        
                        // Przywracanie pliku
                        backup_file.copy(target_file, FileCopyFlags.OVERWRITE);
                        logger.log(LogLevel.INFO, "Przywrócono plik: " + target_path);
                        
                    } catch (Error e) {
                        logger.log(LogLevel.WARNING, "Błąd podczas przywracania pliku " + target_path + ": " + e.message);
                    }
                }
            }
            
            // Przywracanie usług systemd
            var systemd_path = Path.build_filename(config_path, "systemd");
            var systemd_dir = File.new_for_path(systemd_path);
            
            if (systemd_dir.query_exists()) {
                // TODO: Implementacja przywracania usług systemd
                logger.log(LogLevel.INFO, "Przywracanie usług systemd (placeholder)");
            }
            
            logger.log(LogLevel.INFO, "Przywracanie konfiguracji systemu zakończone");
            return true;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas przywracania konfiguracji systemu: " + e.message);
            return false;
        }
    }
    
    /**
     * Przywraca środowisko pulpitu z backupu
     */
    public bool restore_desktop_environment(string backup_path) {
        try {
            logger.log(LogLevel.INFO, "Rozpoczęcie przywracania środowiska pulpitu...");
            
            var desktop_path = Path.build_filename(backup_path, "desktop_environment");
            var desktop_dir = File.new_for_path(desktop_path);
            
            if (!desktop_dir.query_exists()) {
                logger.log(LogLevel.WARNING, "Katalog środowiska pulpitu nie istnieje w backupie");
                return false;
            }
            
            // Przywracanie motywów
            var themes_path = Path.build_filename(desktop_path, "themes_usr_share_themes");
            var themes_dir = File.new_for_path(themes_path);
            
            if (themes_dir.query_exists()) {
                restore_directory_recursive(themes_dir, "/usr/share/themes");
            }
            
            var themes_home_path = Path.build_filename(desktop_path, "themes_.themes");
            var themes_home_dir = File.new_for_path(themes_home_path);
            
            if (themes_home_dir.query_exists()) {
                var home_themes = GLib.Environment.get_home_dir() + "/.themes";
                restore_directory_recursive(themes_home_dir, home_themes);
            }
            
            // Przywracanie ikon
            var icons_path = Path.build_filename(desktop_path, "icons_usr_share_icons");
            var icons_dir = File.new_for_path(icons_path);
            
            if (icons_dir.query_exists()) {
                restore_directory_recursive(icons_dir, "/usr/share/icons");
            }
            
            var icons_home_path = Path.build_filename(desktop_path, "icons_.icons");
            var icons_home_dir = File.new_for_path(icons_home_path);
            
            if (icons_home_dir.query_exists()) {
                var home_icons = GLib.Environment.get_home_dir() + "/.icons";
                restore_directory_recursive(icons_home_dir, home_icons);
            }
            
            // Przywracanie czcionek
            var fonts_path = Path.build_filename(desktop_path, "fonts_usr_share_fonts");
            var fonts_dir = File.new_for_path(fonts_path);
            
            if (fonts_dir.query_exists()) {
                restore_directory_recursive(fonts_dir, "/usr/share/fonts");
            }
            
            var fonts_home_path = Path.build_filename(desktop_path, "fonts_.fonts");
            var fonts_home_dir = File.new_for_path(fonts_home_path);
            
            if (fonts_home_dir.query_exists()) {
                var home_fonts = GLib.Environment.get_home_dir() + "/.fonts";
                restore_directory_recursive(fonts_home_dir, home_fonts);
            }
            
            logger.log(LogLevel.INFO, "Przywracanie środowiska pulpitu zakończone");
            return true;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas przywracania środowiska pulpitu: " + e.message);
            return false;
        }
    }
    
    /**
     * Przywraca wybrane katalogi z backupu
     */
    public bool restore_custom_directories(string backup_path) {
        try {
            logger.log(LogLevel.INFO, "Rozpoczęcie przywracania wybranych katalogów...");
            
            var custom_backup_path = Path.build_filename(backup_path, "custom_directories");
            var custom_backup_dir = File.new_for_path(custom_backup_path);
            
            if (!custom_backup_dir.query_exists()) {
                logger.log(LogLevel.WARNING, "Katalog wybranych katalogów nie istnieje w backupie");
                return false;
            }
            
            var enumerator = custom_backup_dir.enumerate_children("standard::*", FileQueryInfoFlags.NONE);
            FileInfo info;
            
            while ((info = enumerator.next_file()) != null) {
                var backup_dir = custom_backup_dir.get_child(info.get_name());
                var metadata_file = backup_dir.get_child("backup_metadata.json");
                
                if (metadata_file.query_exists()) {
                    try {
                        var parser = new Json.Parser();
                        parser.load_from_file(metadata_file.get_path());
                        var root = parser.get_root();
                        
                        if (root != null && root.get_node_type() == Json.NodeType.OBJECT) {
                            var obj = root.get_object();
                            
                            if (obj.has_member("original_path")) {
                                var original_path = obj.get_string_member("original_path");
                                var target_dir = File.new_for_path(original_path);
                                
                                // Backup istniejącego katalogu
                                if (target_dir.query_exists()) {
                                    var backup_path_old = original_path + ".backup";
                                    var backup_dir_old = File.new_for_path(backup_path_old);
                                    
                                    if (backup_dir_old.query_exists()) {
                                        backup_dir_old.delete();
                                    }
                                    
                                    target_dir.move(backup_dir_old, FileCopyFlags.OVERWRITE);
                                    logger.log(LogLevel.INFO, "Utworzono backup istniejącego katalogu: " + original_path);
                                }
                                
                                // Przywracanie katalogu
                                restore_directory_recursive(backup_dir, original_path);
                                logger.log(LogLevel.INFO, "Przywrócono katalog: " + original_path);
                            }
                        }
                    } catch (Error e) {
                        logger.log(LogLevel.WARNING, "Błąd podczas odczytu metadanych katalogu " + info.get_name() + ": " + e.message);
                        continue;
                    }
                }
            }
            
            logger.log(LogLevel.INFO, "Przywracanie wybranych katalogów zakończone");
            return true;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas przywracania wybranych katalogów: " + e.message);
            return false;
        }
    }
    
    /**
     * Przywraca katalog rekurencyjnie
     */
    private void restore_directory_recursive(File source, string target_path) throws Error {
        var target_dir = File.new_for_path(target_path);
        
        if (!target_dir.query_exists()) {
            target_dir.make_directory_with_parents();
        }
        
        var enumerator = source.enumerate_children("standard::*", FileQueryInfoFlags.NONE);
        FileInfo info;
        
        while ((info = enumerator.next_file()) != null) {
            var source_child = source.get_child(info.get_name());
            var target_child_path = Path.build_filename(target_path, info.get_name());
            var target_child = File.new_for_path(target_child_path);
            
            if (info.get_file_type() == FileType.REGULAR) {
                source_child.copy(target_child, FileCopyFlags.OVERWRITE);
            } else if (info.get_file_type() == FileType.DIRECTORY) {
                restore_directory_recursive(source_child, target_child_path);
            }
        }
    }
    
    /**
     * Przywraca pełny system z backupu
     */
    public bool restore_full_system(string backup_path, List<string>? components = null) {
        try {
            logger.log(LogLevel.INFO, "Rozpoczęcie przywracania pełnego systemu z: " + backup_path);
            
            // Sprawdzenie czy backup istnieje
            var backup_dir = File.new_for_path(backup_path);
            if (!backup_dir.query_exists()) {
                logger.log(LogLevel.ERROR, "Backup nie istnieje: " + backup_path);
                return false;
            }
            
            // Sprawdzenie metadanych backupu
            var metadata_file = backup_dir.get_child("backup_metadata.json");
            if (!metadata_file.query_exists()) {
                logger.log(LogLevel.ERROR, "Brak metadanych w backupie: " + backup_path);
                return false;
            }
            
            // Jeśli nie określono komponentów, przywróć wszystko
            if (components == null) {
                var temp_components = new List<string>();
                components = temp_components;
                components.append("packages");
                components.append("system_config");
                components.append("desktop");
                components.append("custom_directories");
            }
            
            // Przywracanie komponentów
            foreach (var component in components) {
                bool success = false;
                
                switch (component) {
                    case "packages":
                        success = restore_packages(backup_path);
                        break;
                    case "system_config":
                        success = restore_system_config(backup_path);
                        break;
                    case "desktop":
                        success = restore_desktop_environment(backup_path);
                        break;
                    case "custom_directories":
                        success = restore_custom_directories(backup_path);
                        break;
                    default:
                        logger.log(LogLevel.WARNING, "Nieznany komponent do przywracania: " + component);
                        continue;
                }
                
                if (!success) {
                    logger.log(LogLevel.ERROR, "Błąd podczas przywracania komponentu: " + component);
                }
            }
            
            logger.log(LogLevel.INFO, "Przywracanie pełnego systemu zakończone");
            return true;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas przywracania pełnego systemu: " + e.message);
            return false;
        }
    }
    
    /**
     * Zwraca listę dostępnych backupów
     */
    public List<string> get_available_backups(string backup_base_path) {
        var backups = new List<string>();
        
        try {
            var base_dir = File.new_for_path(backup_base_path);
            if (base_dir.query_exists()) {
                var enumerator = base_dir.enumerate_children("standard::*", FileQueryInfoFlags.NONE);
                FileInfo info;
                
                while ((info = enumerator.next_file()) != null) {
                    if (info.get_file_type() == FileType.DIRECTORY) {
                        var backup_dir = base_dir.get_child(info.get_name());
                        var metadata_file = backup_dir.get_child("backup_metadata.json");
                        
                        if (metadata_file.query_exists()) {
                            backups.append(backup_dir.get_path());
                        }
                    }
                }
            }
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas pobierania listy backupów: " + e.message);
        }
        
        return backups;
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
}
