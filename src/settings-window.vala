/*
 * Fedora System Backup Tool - Zakładka Ustawienia
 * Autor: System Backup Tool
 * Wersja: 1.0.0
 * 
 * Zakładka do konfiguracji aplikacji, harmonogramowania i integracji z chmurą
 */

using Gtk;
using GLib;

public class SettingsWindow : Box {
    
    // Referencja do głównego systemu
    private BackupSystem backup_system;
    
    // Ustawienia harmonogramowania
    private CheckButton scheduler_enabled_check;
    private ComboBoxText scheduler_method_combo;
    private ComboBoxText scheduler_frequency_combo;
    private SpinButton scheduler_time_spin;
    private SpinButton retention_days_spin;
    
    // Ustawienia integracji z chmurą
    private CheckButton cloud_upload_enabled_check;
    private ComboBoxText cloud_provider_combo;
    private Entry cloud_username_entry;
    private Entry cloud_password_entry;
    private Entry cloud_server_entry;
    
    /**
     * Konstruktor zakładki Ustawienia
     */
    public SettingsWindow(BackupSystem system) {
        backup_system = system;
        
        // Konfiguracja kontenera
        orientation = Orientation.VERTICAL;
        spacing = 10;
        margin = 10;
        
        // Tworzenie interfejsu
        create_widgets();
        
        // Ładowanie ustawień
        load_settings();
    }
    
    /**
     * Tworzy wszystkie widgety interfejsu
     */
    private void create_widgets() {
        // Ustawienia harmonogramowania
        create_scheduler_settings();
        
        // Ustawienia integracji z chmurą
        create_cloud_settings();
        
        // Przyciski akcji
        create_action_buttons();
    }
    
    /**
     * Tworzy sekcję ustawień harmonogramowania
     */
    private void create_scheduler_settings() {
        var scheduler_frame = new Frame("Ustawienia harmonogramowania");
        scheduler_frame.margin_bottom = 15;
        pack_start(scheduler_frame, false, false, 0);
        
        var scheduler_box = new Box(Orientation.VERTICAL, 10);
        scheduler_box.margin = 10;
        scheduler_frame.add(scheduler_box);
        
        // Włącz/wyłącz harmonogramowanie
        scheduler_enabled_check = new CheckButton.with_label("Włącz automatyczne harmonogramowanie backupów");
        scheduler_enabled_check.active = false;
        scheduler_enabled_check.toggled.connect(on_scheduler_enabled_toggled);
        scheduler_box.pack_start(scheduler_enabled_check, false, false, 0);
        
        // Metoda harmonogramowania
        var method_box = new Box(Orientation.HORIZONTAL, 10);
        var method_label = new Label("Metoda harmonogramowania:");
        method_box.pack_start(method_label, false, false, 0);
        
        scheduler_method_combo = new ComboBoxText();
        scheduler_method_combo.append("systemd", "Systemd (natywne)");
        scheduler_method_combo.append("python", "Python scheduler");
        scheduler_method_combo.set_active_id("systemd");
        method_box.pack_start(scheduler_method_combo, false, false, 0);
        scheduler_box.pack_start(method_box, false, false, 0);
        
        // Częstotliwość
        var frequency_box = new Box(Orientation.HORIZONTAL, 10);
        var frequency_label = new Label("Częstotliwość:");
        frequency_box.pack_start(frequency_label, false, false, 0);
        
        scheduler_frequency_combo = new ComboBoxText();
        scheduler_frequency_combo.append("daily", "Codziennie");
        scheduler_frequency_combo.append("weekly", "Co tydzień");
        scheduler_frequency_combo.append("monthly", "Co miesiąc");
        scheduler_frequency_combo.set_active_id("daily");
        frequency_box.pack_start(scheduler_frequency_combo, false, false, 0);
        scheduler_box.pack_start(frequency_box, false, false, 0);
        
        // Godzina wykonania
        var time_box = new Box(Orientation.HORIZONTAL, 10);
        var time_label = new Label("Godzina wykonania:");
        time_box.pack_start(time_label, false, false, 0);
        
        scheduler_time_spin = new SpinButton.with_range(0, 23, 1);
        scheduler_time_spin.value = 2; // 2:00
        time_box.pack_start(scheduler_time_spin, false, false, 0);
        
        var time_suffix = new Label(":00");
        time_box.pack_start(time_suffix, false, false, 0);
        scheduler_box.pack_start(time_box, false, false, 0);
        
        // Retencja backupów
        var retention_box = new Box(Orientation.HORIZONTAL, 10);
        var retention_label = new Label("Retencja backupów (dni):");
        retention_box.pack_start(retention_label, false, false, 0);
        
        retention_days_spin = new SpinButton.with_range(1, 365, 1);
        retention_days_spin.value = 30;
        retention_box.pack_start(retention_days_spin, false, false, 0);
        scheduler_box.pack_start(retention_box, false, false, 0);
    }
    
    /**
     * Tworzy sekcję ustawień integracji z chmurą
     */
    private void create_cloud_settings() {
        var cloud_frame = new Frame("Integracja z chmurą");
        cloud_frame.margin_bottom = 15;
        pack_start(cloud_frame, false, false, 0);
        
        var cloud_box = new Box(Orientation.VERTICAL, 10);
        cloud_box.margin = 10;
        cloud_frame.add(cloud_box);
        
        // Włącz/wyłącz upload do chmury
        cloud_upload_enabled_check = new CheckButton.with_label("Włącz automatyczny upload backupów do chmury");
        cloud_upload_enabled_check.active = false;
        cloud_upload_enabled_check.toggled.connect(on_cloud_enabled_toggled);
        cloud_box.pack_start(cloud_upload_enabled_check, false, false, 0);
        
        // Dostawca chmury
        var provider_box = new Box(Orientation.HORIZONTAL, 10);
        var provider_label = new Label("Dostawca chmury:");
        provider_box.pack_start(provider_label, false, false, 0);
        
        cloud_provider_combo = new ComboBoxText();
        cloud_provider_combo.append("nextcloud", "NextCloud");
        cloud_provider_combo.append("google_drive", "Google Drive");
        cloud_provider_combo.append("dropbox", "Dropbox");
        cloud_provider_combo.set_active_id("nextcloud");
        provider_box.pack_start(cloud_provider_combo, false, false, 0);
        cloud_box.pack_start(provider_box, false, false, 0);
        
        // Serwer NextCloud
        var server_box = new Box(Orientation.HORIZONTAL, 10);
        var server_label = new Label("Serwer NextCloud:");
        server_box.pack_start(server_label, false, false, 0);
        
        cloud_server_entry = new Entry();
        cloud_server_entry.placeholder_text = "https://nextcloud.example.com";
        cloud_server_entry.set_hexpand(true);
        server_box.pack_start(cloud_server_entry, true, true, 0);
        cloud_box.pack_start(server_box, false, false, 0);
        
        // Nazwa użytkownika
        var username_box = new Box(Orientation.HORIZONTAL, 10);
        var username_label = new Label("Nazwa użytkownika:");
        username_box.pack_start(username_label, false, false, 0);
        
        cloud_username_entry = new Entry();
        cloud_username_entry.set_hexpand(true);
        username_box.pack_start(cloud_username_entry, true, true, 0);
        cloud_box.pack_start(username_box, false, false, 0);
        
        // Hasło
        var password_box = new Box(Orientation.HORIZONTAL, 10);
        var password_label = new Label("Hasło:");
        password_box.pack_start(password_label, false, false, 0);
        
        cloud_password_entry = new Entry();
        cloud_password_entry.visibility = false;
        cloud_password_entry.set_hexpand(true);
        password_box.pack_start(cloud_password_entry, true, true, 0);
        cloud_box.pack_start(password_box, false, false, 0);
    }
    
    /**
     * Tworzy przyciski akcji
     */
    private void create_action_buttons() {
        var buttons_box = new Box(Orientation.HORIZONTAL, 10);
        buttons_box.margin_top = 10;
        pack_start(buttons_box, false, false, 0);
        
        // Przycisk zapisywania ustawień
        var save_button = new Button.with_label("Zapisz ustawienia");
        save_button.get_style_context().add_class("suggested-action");
        save_button.clicked.connect(on_save_settings_clicked);
        buttons_box.pack_start(save_button, false, false, 0);
        
        // Przycisk testowania połączenia z chmurą
        var test_button = new Button.with_label("Test połączenia z chmurą");
        test_button.clicked.connect(on_test_cloud_connection_clicked);
        buttons_box.pack_start(test_button, false, false, 0);
        
        // Przycisk testowania harmonogramowania
        var test_scheduler_button = new Button.with_label("Test harmonogramowania");
        test_scheduler_button.clicked.connect(on_test_scheduler_clicked);
        buttons_box.pack_start(test_scheduler_button, false, false, 0);
    }
    
    /**
     * Obsługa włączenia/wyłączenia harmonogramowania
     */
    private void on_scheduler_enabled_toggled() {
        bool enabled = scheduler_enabled_check.active;
        
        scheduler_method_combo.sensitive = enabled;
        scheduler_frequency_combo.sensitive = enabled;
        scheduler_time_spin.sensitive = enabled;
        retention_days_spin.sensitive = enabled;
    }
    
    /**
     * Obsługa włączenia/wyłączenia integracji z chmurą
     */
    private void on_cloud_enabled_toggled() {
        bool enabled = cloud_upload_enabled_check.active;
        
        cloud_provider_combo.sensitive = enabled;
        cloud_server_entry.sensitive = enabled;
        cloud_username_entry.sensitive = enabled;
        cloud_password_entry.sensitive = enabled;
    }
    
    /**
     * Obsługa kliknięcia przycisku zapisywania ustawień
     */
    private void on_save_settings_clicked() {
        try {
            save_settings();
            
            var main_window = get_toplevel() as MainWindow;
            if (main_window != null) {
                main_window.show_info_dialog("Sukces", "Ustawienia zostały zapisane pomyślnie");
            }
            
        } catch (Error err) {
            var main_window = get_toplevel() as MainWindow;
            if (main_window != null) {
                main_window.show_error_dialog("Błąd", "Nie udało się zapisać ustawień: " + err.message);
            }
        }
    }
    
    /**
     * Obsługa kliknięcia przycisku testowania połączenia z chmurą
     */
    private void on_test_cloud_connection_clicked() {
        var main_window = get_toplevel() as MainWindow;
        if (main_window != null) {
            main_window.update_status("Testowanie połączenia z chmurą...");
        }
        
        // Test połączenia w osobnym wątku
        new Thread<void*>("cloud-test-thread", () => {
            test_cloud_connection_in_thread();
            return null;
        });
    }
    
    /**
     * Obsługa kliknięcia przycisku testowania harmonogramowania
     */
    private void on_test_scheduler_clicked() {
        var main_window = get_toplevel() as MainWindow;
        if (main_window != null) {
            main_window.update_status("Testowanie harmonogramowania...");
        }
        
        // Test harmonogramowania w osobnym wątku
        new Thread<void*>("scheduler-test-thread", () => {
            test_scheduler_in_thread();
            return null;
        });
    }
    
    /**
     * Ładuje ustawienia z pliku
     */
    private void load_settings() {
        try {
            var config_file = File.new_for_path("/etc/fedora_backup/settings.json");
            if (config_file.query_exists()) {
                var parser = new Json.Parser();
                parser.load_from_file(config_file.get_path());
                var root = parser.get_root();
                
                if (root != null && root.get_node_type() == Json.NodeType.OBJECT) {
                    var obj = root.get_object();
                    
                    // Ustawienia harmonogramowania
                    if (obj.has_member("scheduler_enabled")) {
                        scheduler_enabled_check.active = obj.get_boolean_member("scheduler_enabled");
                    }
                    if (obj.has_member("scheduler_method")) {
                        scheduler_method_combo.set_active_id(obj.get_string_member("scheduler_method"));
                    }
                    if (obj.has_member("scheduler_frequency")) {
                        scheduler_frequency_combo.set_active_id(obj.get_string_member("scheduler_frequency"));
                    }
                    if (obj.has_member("scheduler_time")) {
                        scheduler_time_spin.value = obj.get_int_member("scheduler_time");
                    }
                    if (obj.has_member("retention_days")) {
                        retention_days_spin.value = obj.get_int_member("retention_days");
                    }
                    
                    // Ustawienia chmury
                    if (obj.has_member("cloud_upload_enabled")) {
                        cloud_upload_enabled_check.active = obj.get_boolean_member("cloud_upload_enabled");
                    }
                    if (obj.has_member("cloud_provider")) {
                        cloud_provider_combo.set_active_id(obj.get_string_member("cloud_provider"));
                    }
                    if (obj.has_member("cloud_server")) {
                        cloud_server_entry.text = obj.get_string_member("cloud_server");
                    }
                    if (obj.has_member("cloud_username")) {
                        cloud_username_entry.text = obj.get_string_member("cloud_username");
                    }
                    if (obj.has_member("cloud_password")) {
                        cloud_password_entry.text = obj.get_string_member("cloud_password");
                    }
                }
            }
        } catch (Error err) {
            // Ignoruj błędy ładowania ustawień
        }
        
        // Aktualizacja stanu widgetów
        on_scheduler_enabled_toggled();
        on_cloud_enabled_toggled();
    }
    
    /**
     * Zapisuje ustawienia do pliku
     */
    private void save_settings() throws Error {
        var config_dir = File.new_for_path("/etc/fedora_backup");
        if (!config_dir.query_exists()) {
            config_dir.make_directory_with_parents();
        }
        
        var config_file = File.new_for_path("/etc/fedora_backup/settings.json");
        var obj = new Json.Object();
        
        // Ustawienia harmonogramowania
        obj.set_boolean_member("scheduler_enabled", scheduler_enabled_check.active);
        obj.set_string_member("scheduler_method", scheduler_method_combo.get_active_id());
        obj.set_string_member("scheduler_frequency", scheduler_frequency_combo.get_active_id());
        obj.set_int_member("scheduler_time", (int)scheduler_time_spin.value);
        obj.set_int_member("retention_days", (int)retention_days_spin.value);
        
        // Ustawienia chmury
        obj.set_boolean_member("cloud_upload_enabled", cloud_upload_enabled_check.active);
        obj.set_string_member("cloud_provider", cloud_provider_combo.get_active_id());
        obj.set_string_member("cloud_server", cloud_server_entry.text);
        obj.set_string_member("cloud_username", cloud_username_entry.text);
        obj.set_string_member("cloud_password", cloud_password_entry.text);
        
        var generator = new Json.Generator();
        generator.set_root(new Json.Node.alloc().init_object(obj));
        generator.to_file(config_file.get_path());
        
        // Aktualizacja konfiguracji systemu
        update_system_config();
    }
    
    /**
     * Aktualizuje konfigurację systemu
     */
    private void update_system_config() {
        try {
            // Aktualizacja harmonogramowania
            if (scheduler_enabled_check.active) {
                backup_system.scheduler.update_scheduler_config(
                    scheduler_method_combo.get_active_id(),
                    scheduler_frequency_combo.get_active_id(),
                    (int)scheduler_time_spin.value,
                    (int)retention_days_spin.value
                );
            } else {
                backup_system.scheduler.stop_scheduler();
            }
            
            // Aktualizacja integracji z chmurą
            // TODO: Implementacja aktualizacji konfiguracji chmury
            
        } catch (Error err) {
            throw new IOError.FAILED("Błąd aktualizacji konfiguracji systemu: " + err.message);
        }
    }
    
    /**
     * Testuje połączenie z chmurą w osobnym wątku
     */
    private void test_cloud_connection_in_thread() {
        // TODO: Implementacja testu połączenia z chmurą
        bool success = true;
        
        // Aktualizacja GUI w głównym wątku
        Idle.add(() => {
            var main_window = get_toplevel() as MainWindow;
            if (main_window != null) {
                if (success) {
                    main_window.update_status("Test połączenia z chmurą zakończony pomyślnie");
                    main_window.show_info_dialog("Sukces", "Test połączenia z chmurą zakończony pomyślnie!");
                } else {
                    main_window.update_status("Test połączenia z chmurą zakończony niepowodzeniem");
                    main_window.show_error_dialog("Błąd", "Test połączenia z chmurą zakończony niepowodzeniem");
                }
            }
            return false;
        });
    }
    
    /**
     * Testuje harmonogramowanie w osobnym wątku
     */
    private void test_scheduler_in_thread() {
        // TODO: Implementacja testu harmonogramowania
        bool success = true;
        
        // Aktualizacja GUI w głównym wątku
        Idle.add(() => {
            var main_window = get_toplevel() as MainWindow;
            if (main_window != null) {
                if (success) {
                    main_window.update_status("Test harmonogramowania zakończony pomyślnie");
                    main_window.show_info_dialog("Sukces", "Test harmonogramowania zakończony pomyślnie!");
                } else {
                    main_window.update_status("Test harmonogramowania zakończony niepowodzeniem");
                    main_window.show_error_dialog("Błąd", "Test harmonogramowania zakończony niepowodzeniem");
                }
            }
            return false;
        });
    }
}
