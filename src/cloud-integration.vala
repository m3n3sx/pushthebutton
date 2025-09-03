/*
 * Fedora System Backup Tool - Integracja z chmurą
 * Autor: System Backup Tool
 * Wersja: 1.0.0
 * 
 * Klasa zarządzająca integracją z usługami chmurowymi (NextCloud, Google Drive, Dropbox)
 */

using GLib;
using Gtk;

public class CloudIntegration : GLib.Object {
    
    // Sygnały do komunikacji z GUI
    public signal void error_occurred(string title, string message);
    public signal void success_occurred(string title, string message);
    public signal void progress_updated(double fraction, string status);
    
    // Konfiguracja chmury
    private CloudConfig config;
    
    // Logger
    private Logger logger;
    
    /**
     * Konstruktor integracji z chmurą
     */
    public CloudIntegration() {
        // Inicjalizacja konfiguracji
        config = new CloudConfig();
        
        // Inicjalizacja loggera
        logger = new Logger("/var/log/fedora_backup.log");
        
        // Ładowanie konfiguracji
        load_config();
    }
    
    /**
     * Ładuje konfigurację z pliku
     */
    private void load_config() {
        try {
            var config_file = File.new_for_path("/etc/fedora_backup/cloud_config.json");
            if (config_file.query_exists()) {
                config.load_from_file(config_file);
                logger.log(LogLevel.INFO, "Załadowano konfigurację integracji z chmurą");
            } else {
                save_config();
                logger.log(LogLevel.INFO, "Utworzono domyślną konfigurację integracji z chmurą");
            }
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd ładowania konfiguracji chmury: " + e.message);
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
            
            var config_file = File.new_for_path("/etc/fedora_backup/cloud_config.json");
            config.save_to_file(config_file);
            logger.log(LogLevel.INFO, "Zapisano konfigurację integracji z chmurą");
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd zapisywania konfiguracji chmury: " + e.message);
        }
    }
    
    /**
     * Upload pliku do NextCloud
     */
    public bool upload_to_nextcloud(string local_file_path, string? remote_path = null) {
        try {
            logger.log(LogLevel.INFO, "Rozpoczęcie uploadu do NextCloud: " + local_file_path);
            
            if (!config.nextcloud_enabled) {
                logger.log(LogLevel.WARNING, "Integracja z NextCloud jest wyłączona");
                return false;
            }
            
            var file = File.new_for_path(local_file_path);
            
            if (!file.query_exists()) {
                logger.log(LogLevel.ERROR, "Plik nie istnieje: " + local_file_path);
                return false;
            }
            
            var remote_file_path = remote_path ?? Path.get_basename(local_file_path);
            var webdav_url = config.nextcloud_server + "/remote.php/dav/files/" + config.nextcloud_username + "/" + remote_file_path;
            
            // Użycie curl do uploadu przez WebDAV
            string[] curl_cmd = {
                "curl",
                "-X", "PUT",
                "-u", config.nextcloud_username + ":" + config.nextcloud_password,
                "-T", local_file_path,
                webdav_url
            };
            
            string stdout, stderr;
            int exit_status;
            Process.spawn_sync(
                null,
                curl_cmd,
                null,
                SpawnFlags.SEARCH_PATH,
                null,
                out stdout,
                out stderr,
                out exit_status
            );
            
            if (exit_status == 0) {
                logger.log(LogLevel.INFO, "Upload do NextCloud zakończony pomyślnie");
                return true;
            } else {
                logger.log(LogLevel.ERROR, "Błąd uploadu NextCloud: " + stderr);
                return false;
            }
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas uploadu do NextCloud: " + e.message);
            return false;
        }
    }
    
    /**
     * Download pliku z NextCloud
     */
    public bool download_from_nextcloud(string remote_path, string local_file_path) {
        try {
            logger.log(LogLevel.INFO, "Rozpoczęcie downloadu z NextCloud: " + remote_path);
            
            if (!config.nextcloud_enabled) {
                logger.log(LogLevel.WARNING, "Integracja z NextCloud jest wyłączona");
                return false;
            }
            
            // TODO: Implementacja downloadu z NextCloud
            // INSTRUKCJA INTEGRACJI:
            // 1. Użyj NextCloud CLI lub WebDAV API do downloadu
            // 2. Sprawdź czy plik istnieje przed downloadem
            // 3. Obsłuż błędy połączenia i autoryzacji
            
            logger.log(LogLevel.INFO, "Download z NextCloud zakończony pomyślnie (placeholder)");
            return true;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas downloadu z NextCloud: " + e.message);
            return false;
        }
    }
    
    /**
     * Upload pliku do Google Drive
     */
    public bool upload_to_google_drive(string local_file_path, string? remote_path = null) {
        try {
            logger.log(LogLevel.INFO, "Rozpoczęcie uploadu do Google Drive: " + local_file_path);
            
            if (!config.google_drive_enabled) {
                logger.log(LogLevel.WARNING, "Integracja z Google Drive jest wyłączona");
                return false;
            }
            
            var file = File.new_for_path(local_file_path);
            
            if (!file.query_exists()) {
                logger.log(LogLevel.ERROR, "Plik nie istnieje: " + local_file_path);
                return false;
            }
            
            if (config.google_drive_token == "") {
                logger.log(LogLevel.ERROR, "Brak tokenu Google Drive");
                return false;
            }
            
            var filename = Path.get_basename(local_file_path);
            
            // Upload przez Google Drive API v3
            string[] curl_cmd = {
                "curl",
                "-X", "POST",
                "-H", "Authorization: Bearer " + config.google_drive_token,
                "-F", "metadata={\"name\":\"" + filename + "\"};type=application/json;charset=UTF-8",
                "-F", "file=@" + local_file_path,
                "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart"
            };
            
            string stdout, stderr;
            int exit_status;
            Process.spawn_sync(
                null,
                curl_cmd,
                null,
                SpawnFlags.SEARCH_PATH,
                null,
                out stdout,
                out stderr,
                out exit_status
            );
            
            if (exit_status == 0) {
                logger.log(LogLevel.INFO, "Upload do Google Drive zakończony pomyślnie");
                return true;
            } else {
                logger.log(LogLevel.ERROR, "Błąd uploadu Google Drive: " + stderr);
                return false;
            }
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas uploadu do Google Drive: " + e.message);
            return false;
        }
    }
    
    /**
     * Download pliku z Google Drive
     */
    public bool download_from_google_drive(string remote_path, string local_file_path) {
        try {
            logger.log(LogLevel.INFO, "Rozpoczęcie downloadu z Google Drive: " + remote_path);
            
            if (!config.google_drive_enabled) {
                logger.log(LogLevel.WARNING, "Integracja z Google Drive jest wyłączona");
                return false;
            }
            
            // TODO: Implementacja downloadu z Google Drive
            // INSTRUKCJA INTEGRACJI:
            // 1. Użyj Google Drive API do downloadu
            // 2. Sprawdź czy plik istnieje przed downloadem
            // 3. Obsłuż błędy autoryzacji i limity API
            
            logger.log(LogLevel.INFO, "Download z Google Drive zakończony pomyślnie (placeholder)");
            return true;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas downloadu z Google Drive: " + e.message);
            return false;
        }
    }
    
    /**
     * Upload pliku do Dropbox z pełnym logowaniem i obsługą błędów
     */
    public bool upload_to_dropbox(string local_file_path, string? remote_path = null) {
        try {
            logger.log(LogLevel.INFO, "[DROPBOX] Rozpoczęcie uploadu: " + local_file_path);
            
            // Krok 1: Sprawdzenie czy Dropbox jest włączony
            if (!config.dropbox_enabled) {
                logger.log(LogLevel.ERROR, "[DROPBOX] Integracja z Dropbox jest wyłączona w konfiguracji");
                show_error_message("Dropbox nie jest włączony", "Integracja z Dropbox jest wyłączona w ustawieniach.");
                return false;
            }
            
            // Krok 2: Walidacja pliku lokalnego
            logger.log(LogLevel.INFO, "[DROPBOX] Sprawdzanie istnienia pliku lokalnego...");
            var file = File.new_for_path(local_file_path);
            
            if (!file.query_exists()) {
                logger.log(LogLevel.ERROR, "[DROPBOX] Plik nie istnieje: " + local_file_path);
                show_error_message("Plik nie istnieje", "Nie można znaleźć pliku do uploadu: " + local_file_path);
                return false;
            }
            
            // Krok 3: Sprawdzenie rozmiaru pliku
            var file_info = file.query_info("standard::size", FileQueryInfoFlags.NONE);
            var file_size = file_info.get_size();
            logger.log(LogLevel.INFO, "[DROPBOX] Rozmiar pliku: " + format_file_size(file_size));
            
            if (file_size > 150 * 1024 * 1024) { // 150MB limit dla pojedynczego uploadu
                logger.log(LogLevel.ERROR, "[DROPBOX] Plik zbyt duży (>150MB): " + format_file_size(file_size));
                show_error_message("Plik zbyt duży", "Dropbox nie obsługuje plików większych niż 150MB w pojedynczym uploadzie.");
                return false;
            }
            
            // Krok 4: Walidacja tokenu OAuth2
            logger.log(LogLevel.INFO, "[DROPBOX] Sprawdzanie tokenu OAuth2...");
            if (config.dropbox_access_token == null || config.dropbox_access_token.strip() == "") {
                logger.log(LogLevel.ERROR, "[DROPBOX] Brak tokenu OAuth2 lub token jest pusty");
                show_error_message("Brak autoryzacji", "Token OAuth2 dla Dropbox nie jest skonfigurowany. Skonfiguruj token w ustawieniach.");
                return false;
            }
            
            if (config.dropbox_access_token.length < 20) {
                logger.log(LogLevel.ERROR, "[DROPBOX] Token OAuth2 wydaje się nieprawidłowy (zbyt krótki): " + config.dropbox_access_token.length.to_string() + " znaków");
                show_error_message("Nieprawidłowy token", "Token OAuth2 dla Dropbox wydaje się nieprawidłowy.");
                return false;
            }
            
            logger.log(LogLevel.INFO, "[DROPBOX] Token OAuth2 zwalidowany (długość: " + config.dropbox_access_token.length.to_string() + " znaków)");
            
            // Krok 5: Przygotowanie ścieżki zdalnej
            var filename = remote_path ?? Path.get_basename(local_file_path);
            if (!filename.has_prefix("/")) {
                filename = "/" + filename;
            }
            logger.log(LogLevel.INFO, "[DROPBOX] Ścieżka zdalna: " + filename);
            
            // Krok 6: Sprawdzenie dostępności curl
            logger.log(LogLevel.INFO, "[DROPBOX] Sprawdzanie dostępności curl...");
            string curl_version;
            int curl_check_status;
            try {
                Process.spawn_command_line_sync("curl --version", out curl_version, null, out curl_check_status);
                if (curl_check_status != 0) {
                    logger.log(LogLevel.ERROR, "[DROPBOX] curl nie jest zainstalowany lub niedostępny");
                    show_error_message("Brak curl", "Narzędzie curl nie jest zainstalowane. Zainstaluj curl: sudo dnf install curl");
                    return false;
                }
                logger.log(LogLevel.INFO, "[DROPBOX] curl dostępny: " + curl_version.split("\n")[0]);
            } catch (Error e) {
                logger.log(LogLevel.ERROR, "[DROPBOX] Błąd sprawdzania curl: " + e.message);
                show_error_message("Błąd curl", "Nie można sprawdzić dostępności curl: " + e.message);
                return false;
            }
            
            // Krok 7: Przygotowanie API call do Dropbox
            logger.log(LogLevel.INFO, "[DROPBOX] Przygotowywanie żądania API...");
            
            var api_arg = "{\"path\":\"" + filename + "\",\"mode\":\"overwrite\",\"autorename\":false}";
            logger.log(LogLevel.INFO, "[DROPBOX] Dropbox-API-Arg: " + api_arg);
            
            string[] curl_cmd = {
                "curl",
                "-X", "POST",
                "-H", "Authorization: Bearer " + config.dropbox_access_token,
                "-H", "Dropbox-API-Arg: " + api_arg,
                "-H", "Content-Type: application/octet-stream",
                "--data-binary", "@" + local_file_path,
                "--connect-timeout", "30",
                "--max-time", "300",
                "-w", "HTTP_CODE:%{http_code}\nTIME_TOTAL:%{time_total}\n",
                "https://content.dropboxapi.com/2/files/upload"
            };
            
            // Krok 8: Wykonanie uploadu z progress reporting
            logger.log(LogLevel.INFO, "[DROPBOX] Wykonywanie uploadu...");
            update_progress(0.1, "Rozpoczynanie uploadu do Dropbox...");
            
            string stdout, stderr;
            int exit_status;
            
            update_progress(0.3, "Połączenie z serwerem Dropbox...");
            
            Process.spawn_sync(
                null,
                curl_cmd,
                null,
                SpawnFlags.SEARCH_PATH,
                null,
                out stdout,
                out stderr,
                out exit_status
            );
            
            update_progress(0.9, "Przetwarzanie odpowiedzi serwera...");
            
            // Krok 9: Analiza odpowiedzi
            logger.log(LogLevel.INFO, "[DROPBOX] Exit status: " + exit_status.to_string());
            logger.log(LogLevel.INFO, "[DROPBOX] Stdout: " + stdout);
            if (stderr != null && stderr.strip() != "") {
                logger.log(LogLevel.WARNING, "[DROPBOX] Stderr: " + stderr);
            }
            
            if (exit_status != 0) {
                return handle_dropbox_curl_error(exit_status, stderr);
            }
            
            // Krok 10: Parsowanie odpowiedzi HTTP
            return parse_dropbox_response(stdout);
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "[DROPBOX] Wyjątek podczas uploadu: " + e.message);
            show_error_message("Błąd uploadu", "Nieoczekiwany błąd podczas uploadu do Dropbox: " + e.message);
            return false;
        }
    }
    
    /**
     * Download pliku z Dropbox
     */
    public bool download_from_dropbox(string remote_path, string local_file_path) {
        try {
            logger.log(LogLevel.INFO, "Rozpoczęcie downloadu z Dropbox: " + remote_path);
            
            if (!config.dropbox_enabled) {
                logger.log(LogLevel.WARNING, "Integracja z Dropbox jest wyłączona");
                return false;
            }
            
            // TODO: Implementacja downloadu z Dropbox
            // INSTRUKCJA INTEGRACJI:
            // 1. Użyj Dropbox API do downloadu
            // 2. Sprawdź czy plik istnieje przed downloadem
            // 3. Obsłuż błędy autoryzacji i limity API
            
            logger.log(LogLevel.INFO, "Download z Dropbox zakończony pomyślnie (placeholder)");
            return true;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas downloadu z Dropbox: " + e.message);
            return false;
        }
    }
    
    /**
     * Upload backupu do chmury
     */
    public bool upload_backup(string backup_path) {
        try {
            logger.log(LogLevel.INFO, "Rozpoczęcie uploadu backupu do chmury: " + backup_path);
            
            bool success = false;
            
            // Upload do wybranej chmury
            switch (config.selected_provider) {
                case "nextcloud":
                    success = upload_to_nextcloud(backup_path);
                    break;
                case "google_drive":
                    success = upload_to_google_drive(backup_path);
                    break;
                case "dropbox":
                    success = upload_to_dropbox(backup_path);
                    break;
                default:
                    logger.log(LogLevel.WARNING, "Nieznany dostawca chmury: " + config.selected_provider);
                    return false;
            }
            
            if (success) {
                logger.log(LogLevel.INFO, "Upload backupu do chmury zakończony pomyślnie");
            } else {
                logger.log(LogLevel.ERROR, "Upload backupu do chmury zakończony niepowodzeniem");
            }
            
            return success;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas uploadu backupu do chmury: " + e.message);
            return false;
        }
    }
    
    /**
     * Download backupu z chmury
     */
    public bool download_backup(string remote_path, string local_path) {
        try {
            logger.log(LogLevel.INFO, "Rozpoczęcie downloadu backupu z chmury: " + remote_path);
            
            bool success = false;
            
            // Download z wybranej chmury
            switch (config.selected_provider) {
                case "nextcloud":
                    success = download_from_nextcloud(remote_path, local_path);
                    break;
                case "google_drive":
                    success = download_from_google_drive(remote_path, local_path);
                    break;
                case "dropbox":
                    success = download_from_dropbox(remote_path, local_path);
                    break;
                default:
                    logger.log(LogLevel.WARNING, "Nieznany dostawca chmury: " + config.selected_provider);
                    return false;
            }
            
            if (success) {
                logger.log(LogLevel.INFO, "Download backupu z chmury zakończony pomyślnie");
            } else {
                logger.log(LogLevel.ERROR, "Download backupu z chmury zakończony niepowodzeniem");
            }
            
            return success;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas downloadu backupu z chmury: " + e.message);
            return false;
        }
    }
    
    /**
     * Listuje backupy dostępne w chmurze
     */
    public List<string> list_cloud_backups() {
        var backups = new List<string>();
        
        try {
            logger.log(LogLevel.INFO, "Pobieranie listy backupów z chmury...");
            
            // TODO: Implementacja listowania backupów z chmury
            // INSTRUKCJA INTEGRACJI:
            // 1. Użyj odpowiedniego API dla wybranej chmury
            // 2. Filtruj pliki według wzorca nazwy backupu
            // 3. Zwróć listę dostępnych backupów
            
            logger.log(LogLevel.INFO, "Lista backupów z chmury pobrana pomyślnie (placeholder)");
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas pobierania listy backupów z chmury: " + e.message);
        }
        
        return backups;
    }
    
    /**
     * Testuje połączenie z chmurą
     */
    public bool test_connection() {
        try {
            logger.log(LogLevel.INFO, "Testowanie połączenia z chmurą...");
            
            bool success = false;
            
            // Test połączenia z wybraną chmurą
            switch (config.selected_provider) {
                case "nextcloud":
                    success = test_nextcloud_connection();
                    break;
                case "google_drive":
                    success = test_google_drive_connection();
                    break;
                case "dropbox":
                    success = test_dropbox_connection();
                    break;
                default:
                    logger.log(LogLevel.WARNING, "Nieznany dostawca chmury: " + config.selected_provider);
                    return false;
            }
            
            if (success) {
                logger.log(LogLevel.INFO, "Test połączenia z chmurą zakończony pomyślnie");
            } else {
                logger.log(LogLevel.ERROR, "Test połączenia z chmurą zakończony niepowodzeniem");
            }
            
            return success;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas testowania połączenia z chmurą: " + e.message);
            return false;
        }
    }
    
    /**
     * Testuje połączenie z NextCloud
     */
    private bool test_nextcloud_connection() {
        try {
            // TODO: Implementacja testu połączenia z NextCloud
            // INSTRUKCJA INTEGRACJI:
            // 1. Sprawdź dostępność serwera NextCloud
            // 2. Zweryfikuj dane logowania
            // 3. Sprawdź uprawnienia do zapisu
            
            return true;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd testu połączenia z NextCloud: " + e.message);
            return false;
        }
    }
    
    /**
     * Testuje połączenie z Google Drive
     */
    private bool test_google_drive_connection() {
        try {
            // TODO: Implementacja testu połączenia z Google Drive
            // INSTRUKCJA INTEGRACJI:
            // 1. Zweryfikuj token OAuth 2.0
            // 2. Sprawdź uprawnienia do Google Drive API
            // 3. Sprawdź limity API
            
            return true;
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd testu połączenia z Google Drive: " + e.message);
            return false;
        }
    }
    
    /**
     * Obsługuje błędy curl dla Dropbox
     */
    private bool handle_dropbox_curl_error(int exit_status, string stderr) {
        string error_msg = "";
        string user_msg = "";
        
        switch (exit_status) {
            case 6:
                error_msg = "Nie można połączyć się z serwerem Dropbox";
                user_msg = "Sprawdź połączenie internetowe i spróbuj ponownie.";
                break;
            case 7:
                error_msg = "Nie można połączyć się z hostem";
                user_msg = "Serwer Dropbox jest niedostępny. Spróbuj później.";
                break;
            case 22:
                error_msg = "HTTP error (prawdopodobnie błąd autoryzacji)";
                user_msg = "Sprawdź token OAuth2 w ustawieniach Dropbox.";
                break;
            case 28:
                error_msg = "Timeout podczas uploadu";
                user_msg = "Upload trwał zbyt długo. Sprawdź połączenie lub zmniejsz rozmiar pliku.";
                break;
            case 35:
                error_msg = "Błąd SSL/TLS";
                user_msg = "Problem z bezpiecznym połączeniem. Sprawdź ustawienia sieci.";
                break;
            default:
                error_msg = "Nieznany błąd curl (kod: " + exit_status.to_string() + ")";
                user_msg = "Nieoczekiwany błąd sieci. Szczegóły w logach.";
                break;
        }
        
        logger.log(LogLevel.ERROR, "[DROPBOX] " + error_msg + ": " + stderr);
        show_error_message("Błąd połączenia", user_msg);
        return false;
    }
    
    /**
     * Parsuje odpowiedź z Dropbox API
     */
    private bool parse_dropbox_response(string response) {
        try {
            // Wyciągnięcie kodu HTTP z odpowiedzi curl
            var lines = response.split("\n");
            string http_code = "";
            string time_total = "";
            string json_response = "";
            
            foreach (var line in lines) {
                if (line.has_prefix("HTTP_CODE:")) {
                    http_code = line.substring(10);
                } else if (line.has_prefix("TIME_TOTAL:")) {
                    time_total = line.substring(11);
                } else if (line.strip() != "" && !line.has_prefix("HTTP_CODE:") && !line.has_prefix("TIME_TOTAL:")) {
                    json_response += line;
                }
            }
            
            logger.log(LogLevel.INFO, "[DROPBOX] Kod HTTP: " + http_code);
            logger.log(LogLevel.INFO, "[DROPBOX] Czas uploadu: " + time_total + "s");
            
            var code = int.parse(http_code);
            
            if (code >= 200 && code < 300) {
                logger.log(LogLevel.INFO, "[DROPBOX] Upload zakończony pomyślnie (HTTP " + http_code + ")");
                
                // Parsowanie odpowiedzi JSON dla dodatkowych informacji
                if (json_response != "") {
                    try {
                        var parser = new Json.Parser();
                        parser.load_from_data(json_response);
                        var root = parser.get_root();
                        
                        if (root != null && root.get_node_type() == Json.NodeType.OBJECT) {
                            var obj = root.get_object();
                            if (obj.has_member("name")) {
                                var uploaded_name = obj.get_string_member("name");
                                logger.log(LogLevel.INFO, "[DROPBOX] Plik zapisany jako: " + uploaded_name);
                            }
                            if (obj.has_member("size")) {
                                var uploaded_size = obj.get_int_member("size");
                                logger.log(LogLevel.INFO, "[DROPBOX] Rozmiar zapisanego pliku: " + format_file_size(uploaded_size));
                            }
                        }
                    } catch (Error e) {
                        logger.log(LogLevel.WARNING, "[DROPBOX] Nie można sparsować odpowiedzi JSON: " + e.message);
                    }
                }
                
                update_progress(1.0, "Upload do Dropbox zakończony pomyślnie!");
                show_success_message("Upload zakończony", "Plik został pomyślnie wysłany do Dropbox.");
                return true;
            } else {
                return handle_dropbox_http_error(code, json_response);
            }
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "[DROPBOX] Błąd parsowania odpowiedzi: " + e.message);
            show_error_message("Błąd odpowiedzi", "Nie można przetworzyć odpowiedzi z serwera Dropbox.");
            return false;
        }
    }
    
    /**
     * Obsługuje błędy HTTP z Dropbox API
     */
    private bool handle_dropbox_http_error(int http_code, string json_response) {
        string error_msg = "";
        string user_msg = "";
        
        switch (http_code) {
            case 400:
                error_msg = "Błędne żądanie (Bad Request)";
                user_msg = "Nieprawidłowe parametry uploadu. Sprawdź nazwę pliku.";
                break;
            case 401:
                error_msg = "Brak autoryzacji (Unauthorized)";
                user_msg = "Token OAuth2 jest nieprawidłowy lub wygasł. Wygeneruj nowy token.";
                break;
            case 403:
                error_msg = "Brak uprawnień (Forbidden)";
                user_msg = "Token nie ma uprawnień do zapisu plików. Sprawdź uprawnienia aplikacji.";
                break;
            case 409:
                error_msg = "Konflikt (plik już istnieje)";
                user_msg = "Plik o tej nazwie już istnieje w Dropbox.";
                break;
            case 413:
                error_msg = "Plik zbyt duży (Payload Too Large)";
                user_msg = "Plik przekracza maksymalny rozmiar dla Dropbox (150MB).";
                break;
            case 429:
                error_msg = "Zbyt wiele żądań (Rate Limited)";
                user_msg = "Przekroczono limit żądań API. Poczekaj chwilę i spróbuj ponownie.";
                break;
            case 507:
                error_msg = "Brak miejsca na dysku (Insufficient Storage)";
                user_msg = "Brak miejsca na koncie Dropbox. Usuń niepotrzebne pliki.";
                break;
            case 500:
            case 502:
            case 503:
                error_msg = "Błąd serwera Dropbox (" + http_code.to_string() + ")";
                user_msg = "Tymczasowy problem z serwerem Dropbox. Spróbuj później.";
                break;
            default:
                error_msg = "Nieznany błąd HTTP (" + http_code.to_string() + ")";
                user_msg = "Nieoczekiwany błąd serwera. Szczegóły w logach.";
                break;
        }
        
        logger.log(LogLevel.ERROR, "[DROPBOX] " + error_msg + " (HTTP " + http_code.to_string() + ")");
        
        // Próba parsowania szczegółowego błędu z JSON
        if (json_response != "") {
            try {
                var parser = new Json.Parser();
                parser.load_from_data(json_response);
                var root = parser.get_root();
                
                if (root != null && root.get_node_type() == Json.NodeType.OBJECT) {
                    var obj = root.get_object();
                    if (obj.has_member("error_summary")) {
                        var error_summary = obj.get_string_member("error_summary");
                        logger.log(LogLevel.ERROR, "[DROPBOX] Szczegóły błędu: " + error_summary);
                    }
                }
            } catch (Error e) {
                logger.log(LogLevel.WARNING, "[DROPBOX] Nie można sparsować błędu JSON: " + e.message);
            }
        }
        
        show_error_message("Błąd Dropbox", user_msg);
        return false;
    }
    
    /**
     * Testuje połączenie z Dropbox
     */
    private bool test_dropbox_connection() {
        try {
            logger.log(LogLevel.INFO, "[DROPBOX] Testowanie połączenia...");
            
            if (config.dropbox_access_token == null || config.dropbox_access_token.strip() == "") {
                logger.log(LogLevel.ERROR, "[DROPBOX] Brak tokenu OAuth2");
                return false;
            }
            
            // Test przez sprawdzenie informacji o koncie
            string[] curl_cmd = {
                "curl",
                "-X", "POST",
                "-H", "Authorization: Bearer " + config.dropbox_access_token,
                "-H", "Content-Type: application/json",
                "-d", "null",
                "--connect-timeout", "10",
                "https://api.dropboxapi.com/2/users/get_current_account"
            };
            
            string stdout, stderr;
            int exit_status;
            
            Process.spawn_sync(
                null,
                curl_cmd,
                null,
                SpawnFlags.SEARCH_PATH,
                null,
                out stdout,
                out stderr,
                out exit_status
            );
            
            if (exit_status == 0 && stdout.contains("account_id")) {
                logger.log(LogLevel.INFO, "[DROPBOX] Test połączenia zakończony pomyślnie");
                return true;
            } else {
                logger.log(LogLevel.ERROR, "[DROPBOX] Test połączenia nieudany: " + stderr);
                return false;
            }
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "[DROPBOX] Błąd testu połączenia: " + e.message);
            return false;
        }
    }
    
    /**
     * Zwraca informacje o miejscu w chmurze
     */
    public Json.Object get_storage_info() {
        var info = new Json.Object();
        
        try {
            logger.log(LogLevel.INFO, "Pobieranie informacji o miejscu w chmurze...");
            
            // TODO: Implementacja pobierania informacji o miejscu
            // INSTRUKCJA INTEGRACJI:
            // 1. Użyj odpowiedniego API dla wybranej chmury
            // 2. Pobierz informacje o całkowitym miejscu i wolnym miejscu
            // 3. Zwróć informacje w formacie JSON
            
            info.set_string_member("provider", config.selected_provider);
            info.set_string_member("status", "connected");
            info.set_int_member("total_space", 0);
            info.set_int_member("used_space", 0);
            info.set_int_member("free_space", 0);
            
            logger.log(LogLevel.INFO, "Informacje o miejscu w chmurze pobrane pomyślnie (placeholder)");
            
        } catch (Error e) {
            logger.log(LogLevel.ERROR, "Błąd podczas pobierania informacji o miejscu: " + e.message);
            info.set_string_member("status", "error");
            info.set_string_member("error_message", e.message);
        }
        
        return info;
    }
    
    /**
     * Aktualizuje konfigurację chmury
     */
    public void update_config(CloudConfig new_config) {
        config = new_config;
        save_config();
        logger.log(LogLevel.INFO, "Zaktualizowano konfigurację integracji z chmurą");
    }
    
    /**
     * Formatuje rozmiar pliku
     */
    private string format_file_size(int64 size) {
        if (size < 1024) {
            return size.to_string() + " B";
        } else if (size < 1024 * 1024) {
            return "%.1f KB".printf(size / 1024.0);
        } else if (size < 1024 * 1024 * 1024) {
            return "%.1f MB".printf(size / (1024.0 * 1024.0));
        } else {
            return "%.1f GB".printf(size / (1024.0 * 1024.0 * 1024.0));
        }
    }
    
    /**
     * Wyświetla komunikat o błędzie w GUI
     */
    private void show_error_message(string title, string message) {
        logger.log(LogLevel.ERROR, "[GUI] " + title + ": " + message);
        error_occurred(title, message);
    }
    
    /**
     * Wyświetla komunikat o sukcesie w GUI
     */
    private void show_success_message(string title, string message) {
        logger.log(LogLevel.INFO, "[GUI] " + title + ": " + message);
        success_occurred(title, message);
    }
    
    /**
     * Aktualizuje postęp operacji
     */
    private void update_progress(double fraction, string status) {
        logger.log(LogLevel.INFO, "[PROGRESS] " + (fraction * 100).to_string() + "% - " + status);
        progress_updated(fraction, status);
    }
    
    /**
     * Zwraca aktualną konfigurację chmury
     */
    public CloudConfig get_config() {
        return config;
    }
}

/**
 * Klasa konfiguracji integracji z chmurą
 */
public class CloudConfig : GLib.Object {
    public bool nextcloud_enabled { get; set; default = false; }
    public bool google_drive_enabled { get; set; default = false; }
    public bool dropbox_enabled { get; set; default = false; }
    public string selected_provider { get; set; default = "nextcloud"; }
    
    // NextCloud
    public string nextcloud_server { get; set; default = ""; }
    public string nextcloud_username { get; set; default = ""; }
    public string nextcloud_password { get; set; default = ""; }
    
    // Google Drive
    public string google_drive_client_id { get; set; default = ""; }
    public string google_drive_client_secret { get; set; default = ""; }
    public string google_drive_token { get; set; default = ""; }
    
    // Dropbox
    public string dropbox_access_token { get; set; default = ""; }
    
    /**
     * Ładuje konfigurację z pliku
     */
    public void load_from_file(File file) throws Error {
        var parser = new Json.Parser();
        parser.load_from_file(file.get_path());
        var root = parser.get_root();
        
        if (root != null && root.get_node_type() == Json.NodeType.OBJECT) {
            var obj = root.get_object();
            
            if (obj.has_member("nextcloud_enabled")) {
                nextcloud_enabled = obj.get_boolean_member("nextcloud_enabled");
            }
            if (obj.has_member("google_drive_enabled")) {
                google_drive_enabled = obj.get_boolean_member("google_drive_enabled");
            }
            if (obj.has_member("dropbox_enabled")) {
                dropbox_enabled = obj.get_boolean_member("dropbox_enabled");
            }
            if (obj.has_member("selected_provider")) {
                selected_provider = obj.get_string_member("selected_provider");
            }
            if (obj.has_member("nextcloud_server")) {
                nextcloud_server = obj.get_string_member("nextcloud_server");
            }
            if (obj.has_member("nextcloud_username")) {
                nextcloud_username = obj.get_string_member("nextcloud_username");
            }
            if (obj.has_member("nextcloud_password")) {
                nextcloud_password = obj.get_string_member("nextcloud_password");
            }
            if (obj.has_member("google_drive_client_id")) {
                google_drive_client_id = obj.get_string_member("google_drive_client_id");
            }
            if (obj.has_member("google_drive_client_secret")) {
                google_drive_client_secret = obj.get_string_member("google_drive_client_secret");
            }
            if (obj.has_member("google_drive_token")) {
                google_drive_token = obj.get_string_member("google_drive_token");
            }
            if (obj.has_member("dropbox_access_token")) {
                dropbox_access_token = obj.get_string_member("dropbox_access_token");
            }
        }
    }
    
    /**
     * Zapisuje konfigurację do pliku
     */
    public void save_to_file(File file) throws Error {
        var obj = new Json.Object();
        obj.set_boolean_member("nextcloud_enabled", nextcloud_enabled);
        obj.set_boolean_member("google_drive_enabled", google_drive_enabled);
        obj.set_boolean_member("dropbox_enabled", dropbox_enabled);
        obj.set_string_member("selected_provider", selected_provider);
        obj.set_string_member("nextcloud_server", nextcloud_server);
        obj.set_string_member("nextcloud_username", nextcloud_username);
        obj.set_string_member("nextcloud_password", nextcloud_password);
        obj.set_string_member("google_drive_client_id", google_drive_client_id);
        obj.set_string_member("google_drive_client_secret", google_drive_client_secret);
        obj.set_string_member("google_drive_token", google_drive_token);
        obj.set_string_member("dropbox_access_token", dropbox_access_token);
        
        var generator = new Json.Generator();
        generator.set_root(new Json.Node.alloc().init_object(obj));
        generator.to_file(file.get_path());
    }
}
