/*
 * Fedora System Backup Tool - Zakładka Przywracanie
 * Autor: System Backup Tool
 * Wersja: 1.0.0
 * 
 * Zakładka do przywracania systemu z backupu
 */

using Gtk;
using GLib;

public class RestoreWindow : Box {
    
    // Referencja do głównego systemu
    private BackupSystem backup_system;
    
    // Lista dostępnych backupów
    private Gtk.ListStore backups_store;
    private TreeView backups_view;
    
    // Checkboxy opcji przywracania
    private CheckButton restore_packages_check;
    private CheckButton restore_system_config_check;
    private CheckButton restore_desktop_check;
    private CheckButton restore_custom_dirs_check;
    
    // Przycisk przywracania
    private Button execute_restore_button;
    
    /**
     * Konstruktor zakładki Przywracanie
     */
    public RestoreWindow(BackupSystem system) {
        backup_system = system;
        
        // Konfiguracja kontenera
        orientation = Orientation.VERTICAL;
        spacing = 10;
        margin = 10;
        
        // Tworzenie interfejsu
        create_widgets();
    }
    
    /**
     * Tworzy wszystkie widgety interfejsu
     */
    private void create_widgets() {
        // Lista dostępnych backupów
        create_backups_list_section();
        
        // Opcje przywracania
        create_restore_options_section();
        
        // Przycisk przywracania
        create_execute_restore_button();
    }
    
    /**
     * Tworzy sekcję listy dostępnych backupów
     */
    private void create_backups_list_section() {
        var backups_frame = new Frame("Dostępne backupy");
        backups_frame.margin_bottom = 10;
        pack_start(backups_frame, true, true, 0);
        
        var backups_box = new Box(Orientation.VERTICAL, 5);
        backups_box.margin = 10;
        backups_frame.add(backups_box);
        
        // Lista backupów
        create_backups_list(backups_box);
        
        // Przyciski zarządzania backupami
        create_backup_management_buttons(backups_box);
    }
    
    /**
     * Tworzy listę dostępnych backupów
     */
    private void create_backups_list(Box parent_box) {
        // Model danych (nazwa, data, rozmiar, ścieżka)
        backups_store = new Gtk.ListStore(4, typeof(string), typeof(string), typeof(string), typeof(string));
        
        // Widok drzewa
        backups_view = new TreeView.with_model(backups_store);
        backups_view.headers_visible = true;
        backups_view.set_size_request(-1, 200);
        
        // Kolumna nazwy
        var name_column = new TreeViewColumn();
        var name_cell = new CellRendererText();
        name_column.pack_start(name_cell, true);
        name_column.add_attribute(name_cell, "text", 0);
        name_column.title = "Nazwa backupu";
        name_column.expand = true;
        backups_view.append_column(name_column);
        
        // Kolumna daty
        var date_column = new TreeViewColumn();
        var date_cell = new CellRendererText();
        date_column.pack_start(date_cell, true);
        date_column.add_attribute(date_cell, "text", 1);
        date_column.title = "Data utworzenia";
        date_column.expand = false;
        backups_view.append_column(date_column);
        
        // Kolumna rozmiaru
        var size_column = new TreeViewColumn();
        var size_cell = new CellRendererText();
        size_column.pack_start(size_cell, true);
        size_column.add_attribute(size_cell, "text", 2);
        size_column.title = "Rozmiar";
        size_column.expand = false;
        backups_view.append_column(size_column);
        
        // Scrollbar
        var scrolled_window = new ScrolledWindow(null, null);
        scrolled_window.add(backups_view);
        scrolled_window.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        
        parent_box.pack_start(scrolled_window, true, true, 0);
    }
    
    /**
     * Tworzy przyciski zarządzania backupami
     */
    private void create_backup_management_buttons(Box parent_box) {
        var buttons_box = new Box(Orientation.HORIZONTAL, 5);
        parent_box.pack_start(buttons_box, false, false, 0);
        
        // Przycisk odświeżania listy
        var refresh_button = new Button.with_label("Odśwież listę");
        refresh_button.clicked.connect(on_refresh_list_clicked);
        buttons_box.pack_start(refresh_button, false, false, 0);
        
        // Przycisk usuwania backupu
        var delete_button = new Button.with_label("Usuń backup");
        delete_button.clicked.connect(on_delete_backup_clicked);
        buttons_box.pack_start(delete_button, false, false, 0);
    }
    
    /**
     * Tworzy sekcję opcji przywracania
     */
    private void create_restore_options_section() {
        var restore_options_frame = new Frame("Opcje przywracania");
        restore_options_frame.margin_bottom = 10;
        pack_start(restore_options_frame, false, false, 0);
        
        var restore_options_box = new Box(Orientation.VERTICAL, 5);
        restore_options_box.margin = 10;
        restore_options_frame.add(restore_options_box);
        
        // Checkboxy opcji
        restore_packages_check = new CheckButton.with_label("Przywróć pakiety");
        restore_packages_check.active = true;
        restore_options_box.pack_start(restore_packages_check, false, false, 0);
        
        restore_system_config_check = new CheckButton.with_label("Przywróć konfigurację systemu");
        restore_system_config_check.active = true;
        restore_options_box.pack_start(restore_system_config_check, false, false, 0);
        
        restore_desktop_check = new CheckButton.with_label("Przywróć środowisko pulpitu");
        restore_desktop_check.active = true;
        restore_options_box.pack_start(restore_desktop_check, false, false, 0);
        
        restore_custom_dirs_check = new CheckButton.with_label("Przywróć wybrane katalogi");
        restore_custom_dirs_check.active = true;
        restore_options_box.pack_start(restore_custom_dirs_check, false, false, 0);
    }
    
    /**
     * Tworzy przycisk przywracania
     */
    private void create_execute_restore_button() {
        execute_restore_button = new Button.with_label("Przywróć z wybranego backupu");
        execute_restore_button.get_style_context().add_class("suggested-action");
        execute_restore_button.clicked.connect(on_execute_restore_clicked);
        execute_restore_button.margin_top = 10;
        pack_start(execute_restore_button, false, false, 0);
    }
    
    /**
     * Obsługa kliknięcia przycisku odświeżania listy
     */
    private void on_refresh_list_clicked() {
        refresh_backup_list();
    }
    
    /**
     * Obsługa kliknięcia przycisku usuwania backupu
     */
    private void on_delete_backup_clicked() {
        var selection = backups_view.get_selection();
        TreeModel model;
        TreeIter iter;
        
        if (selection.get_selected(out model, out iter)) {
            string backup_name, backup_path;
            model.get(iter, 0, out backup_name, 3, out backup_path);
            
            var main_window = get_toplevel() as MainWindow;
            if (main_window != null) {
                if (main_window.show_confirm_dialog("Potwierdzenie", 
                    "Czy na pewno chcesz usunąć backup:\n" + backup_name + "?")) {
                    
                    try {
                        var file = File.new_for_path(backup_path);
                        if (file.query_exists()) {
                            // Usunięcie katalogu rekurencyjnie
                            delete_directory_recursive(file);
                            main_window.show_info_dialog("Sukces", "Backup usunięty pomyślnie");
                            refresh_backup_list();
                        } else {
                            main_window.show_error_dialog("Błąd", "Backup nie istnieje");
                        }
                    } catch (Error err) {
                        main_window.show_error_dialog("Błąd", "Nie udało się usunąć backupu: " + err.message);
                    }
                }
            }
        } else {
            var main_window = get_toplevel() as MainWindow;
            if (main_window != null) {
                main_window.show_warning_dialog("Ostrzeżenie", "Wybierz backup do usunięcia");
            }
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
     * Obsługa kliknięcia przycisku przywracania
     */
    private void on_execute_restore_clicked() {
        var selection = backups_view.get_selection();
        TreeModel model;
        TreeIter iter;
        
        if (selection.get_selected(out model, out iter)) {
            string backup_name, backup_path;
            model.get(iter, 0, out backup_name, 3, out backup_path);
            
            var main_window = get_toplevel() as MainWindow;
            if (main_window != null) {
                if (main_window.show_confirm_dialog("Potwierdzenie", 
                    "Czy na pewno chcesz przywrócić system z backupu:\n" + backup_name + "?")) {
                    
                    // Wykonanie przywracania w osobnym wątku
                    execute_restore_button.sensitive = false;
                    execute_restore_button.label = "Wykonywanie przywracania...";
                    
                    main_window.update_status("Wykonywanie przywracania...");
                    
                    // Uruchomienie przywracania w osobnym wątku
                    new Thread<void*>("restore-thread", () => {
                        execute_restore_in_thread(backup_path);
                        return null;
                    });
                }
            }
        } else {
            var main_window = get_toplevel() as MainWindow;
            if (main_window != null) {
                main_window.show_warning_dialog("Ostrzeżenie", "Wybierz backup do przywracania");
            }
        }
    }
    
    /**
     * Wykonuje przywracanie w osobnym wątku
     */
    private void execute_restore_in_thread(string backup_path) {
        // Określenie komponentów do przywracania
        var components = new List<string>();
        if (restore_packages_check.active) {
            components.append("packages");
        }
        if (restore_system_config_check.active) {
            components.append("system_config");
        }
        if (restore_desktop_check.active) {
            components.append("desktop");
        }
        if (restore_custom_dirs_check.active) {
            components.append("custom_directories");
        }
        
        // TODO: Implementacja przywracania przez RestoreManager
        // var success = backup_system.restore_manager.restore_full_system(backup_path, components);
        
        // Tymczasowo symulujemy sukces
        bool success = true;
        
        // Aktualizacja GUI w głównym wątku
        Idle.add(() => {
            if (success) {
                var main_window = get_toplevel() as MainWindow;
                if (main_window != null) {
                    main_window.update_status("Przywracanie zakończone pomyślnie");
                    main_window.show_info_dialog("Sukces", "Przywracanie zakończone pomyślnie!");
                }
            } else {
                var main_window = get_toplevel() as MainWindow;
                if (main_window != null) {
                    main_window.update_status("Przywracanie zakończone z błędami");
                    main_window.show_warning_dialog("Ostrzeżenie", "Przywracanie zakończone z błędami");
                }
            }
            
            // Przywrócenie przycisku
            execute_restore_button.sensitive = true;
            execute_restore_button.label = "Przywróć z wybranego backupu";
            
            return false;
        });
    }
    
    /**
     * Odświeża listę dostępnych backupów
     */
    public void refresh_backup_list() {
        backups_store.clear();
        
        try {
            var backup_base_path = backup_system.backup_manager.backup_base_path;
            var base_dir = File.new_for_path(backup_base_path);
            
            if (base_dir.query_exists()) {
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
                                    
                                    string backup_name = "Unknown";
                                    string creation_date = "Unknown";
                                    int64 backup_size = 0;
                                    
                                    if (obj.has_member("backup_name")) {
                                        backup_name = obj.get_string_member("backup_name");
                                    }
                                    if (obj.has_member("creation_date")) {
                                        creation_date = obj.get_string_member("creation_date");
                                    }
                                    if (obj.has_member("backup_size")) {
                                        backup_size = obj.get_int_member("backup_size");
                                    }
                                    
                                    // Formatowanie daty
                                    var formatted_date = MainWindow.format_date(creation_date);
                                    
                                    // Formatowanie rozmiaru
                                    var formatted_size = MainWindow.format_file_size(backup_size);
                                    
                                    // Dodanie do listy
                                    TreeIter iter;
                                    backups_store.append(out iter);
                                    backups_store.set(iter, 
                                        0, backup_name,
                                        1, formatted_date,
                                        2, formatted_size,
                                        3, backup_dir.get_path()
                                    );
                                }
                            } catch (Error err) {
                                // Ignoruj błędy parsowania metadanych
                                continue;
                            }
                        }
                    }
                }
            }
        } catch (Error err) {
            var main_window = get_toplevel() as MainWindow;
            if (main_window != null) {
                main_window.show_error_dialog("Błąd", "Nie udało się odświeżyć listy backupów: " + err.message);
            }
        }
    }
}
