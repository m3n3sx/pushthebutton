/*
 * Fedora System Backup Tool - Zakładka Backup
 * Autor: System Backup Tool
 * Wersja: 1.0.0
 * 
 * Zakładka do zarządzania backupem systemu z opcjami i wyborem katalogów
 */

using Gtk;
using GLib;

public class BackupWindow : Box {
    
    // Referencja do głównego systemu
    private BackupSystem backup_system;
    
    // Checkboxy opcji backupu
    private CheckButton backup_packages_check;
    private CheckButton backup_system_config_check;
    private CheckButton backup_desktop_check;
    private CheckButton backup_custom_dirs_check;
    
    // Lista wybranych katalogów
    private Gtk.ListStore custom_dirs_store;
    private TreeView custom_dirs_view;
    
    // Pole nazwy backupu
    private Entry backup_name_entry;
    
    // Przycisk wykonania backupu
    private Button execute_backup_button;
    
    /**
     * Konstruktor zakładki Backup
     */
    public BackupWindow(BackupSystem system) {
        backup_system = system;
        
        // Konfiguracja kontenera
        orientation = Orientation.VERTICAL;
        spacing = 10;
        margin = 10;
        
        // Tworzenie interfejsu
        create_widgets();
        
        // Aktualizacja listy katalogów
        update_custom_dirs_list();
    }
    
    /**
     * Tworzy wszystkie widgety interfejsu
     */
    private void create_widgets() {
        // Opcje backupu
        create_backup_options();
        
        // Zarządzanie wybranymi katalogami
        create_custom_directories_section();
        
        // Nazwa backupu
        create_backup_name_section();
        
        // Przycisk wykonania backupu
        create_execute_button();
    }
    
    /**
     * Tworzy sekcję opcji backupu
     */
    private void create_backup_options() {
        var options_frame = new Frame("Opcje backupu");
        options_frame.margin_bottom = 10;
        pack_start(options_frame, false, false, 0);
        
        var options_box = new Box(Orientation.VERTICAL, 5);
        options_box.margin = 10;
        options_frame.add(options_box);
        
        // Checkboxy opcji
        backup_packages_check = new CheckButton.with_label("Backup pakietów DNF i Flatpak");
        backup_packages_check.active = true;
        options_box.pack_start(backup_packages_check, false, false, 0);
        
        backup_system_config_check = new CheckButton.with_label("Backup konfiguracji systemu (/etc, systemd)");
        backup_system_config_check.active = true;
        options_box.pack_start(backup_system_config_check, false, false, 0);
        
        backup_desktop_check = new CheckButton.with_label("Backup środowiska pulpitu (motywy, ikony, czcionki)");
        backup_desktop_check.active = true;
        options_box.pack_start(backup_desktop_check, false, false, 0);
        
        backup_custom_dirs_check = new CheckButton.with_label("Backup wybranych katalogów");
        backup_custom_dirs_check.active = true;
        options_box.pack_start(backup_custom_dirs_check, false, false, 0);
    }
    
    /**
     * Tworzy sekcję zarządzania wybranymi katalogami
     */
    private void create_custom_directories_section() {
        var custom_dirs_frame = new Frame("Wybrane katalogi do backupu");
        custom_dirs_frame.margin_bottom = 10;
        pack_start(custom_dirs_frame, true, true, 0);
        
        var custom_dirs_box = new Box(Orientation.VERTICAL, 5);
        custom_dirs_box.margin = 10;
        custom_dirs_frame.add(custom_dirs_box);
        
        // Lista wybranych katalogów
        create_custom_dirs_list(custom_dirs_box);
        
        // Przyciski zarządzania katalogami
        create_directory_management_buttons(custom_dirs_box);
    }
    
    /**
     * Tworzy listę wybranych katalogów
     */
    private void create_custom_dirs_list(Box parent_box) {
        // Model danych
        custom_dirs_store = new Gtk.ListStore(1, typeof(string));
        
        // Widok drzewa
        custom_dirs_view = new TreeView.with_model(custom_dirs_store);
        custom_dirs_view.headers_visible = false;
        custom_dirs_view.set_size_request(-1, 150);
        
        // Kolumna ścieżki
        var path_column = new TreeViewColumn();
        var path_cell = new CellRendererText();
        path_column.pack_start(path_cell, true);
        path_column.add_attribute(path_cell, "text", 0);
        path_column.title = "Ścieżka katalogu";
        custom_dirs_view.append_column(path_column);
        
        // Scrollbar
        var scrolled_window = new ScrolledWindow(null, null);
        scrolled_window.add(custom_dirs_view);
        scrolled_window.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        
        parent_box.pack_start(scrolled_window, true, true, 0);
    }
    
    /**
     * Tworzy przyciski zarządzania katalogami
     */
    private void create_directory_management_buttons(Box parent_box) {
        var buttons_box = new Box(Orientation.HORIZONTAL, 5);
        parent_box.pack_start(buttons_box, false, false, 0);
        
        // Przycisk dodawania katalogu
        var add_button = new Button.with_label("Dodaj katalog");
        add_button.clicked.connect(on_add_directory_clicked);
        buttons_box.pack_start(add_button, false, false, 0);
        
        // Przycisk usuwania katalogu
        var remove_button = new Button.with_label("Usuń katalog");
        remove_button.clicked.connect(on_remove_directory_clicked);
        buttons_box.pack_start(remove_button, false, false, 0);
    }
    
    /**
     * Tworzy sekcję nazwy backupu
     */
    private void create_backup_name_section() {
        var name_frame = new Frame("Nazwa backupu");
        name_frame.margin_bottom = 10;
        pack_start(name_frame, false, false, 0);
        
        var name_box = new Box(Orientation.HORIZONTAL, 10);
        name_box.margin = 10;
        name_frame.add(name_box);
        
        var name_label = new Label("Nazwa backupu:");
        name_box.pack_start(name_label, false, false, 0);
        
        backup_name_entry = new Entry();
        backup_name_entry.text = "fedora_backup";
        backup_name_entry.set_hexpand(true);
        name_box.pack_start(backup_name_entry, true, true, 0);
    }
    
    /**
     * Tworzy przycisk wykonania backupu
     */
    private void create_execute_button() {
        execute_backup_button = new Button.with_label("Wykonaj backup");
        execute_backup_button.get_style_context().add_class("suggested-action");
        execute_backup_button.clicked.connect(on_execute_backup_clicked);
        execute_backup_button.margin_top = 10;
        pack_start(execute_backup_button, false, false, 0);
    }
    
    /**
     * Obsługa kliknięcia przycisku dodawania katalogu
     */
    private void on_add_directory_clicked() {
        var main_window = get_toplevel() as MainWindow;
        if (main_window != null) {
            var directory = main_window.show_folder_chooser_dialog("Wybierz katalog do backupu");
            if (directory != null) {
                if (backup_system.backup_manager.add_custom_directory(directory)) {
                    update_custom_dirs_list();
                    main_window.show_info_dialog("Sukces", "Dodano katalog: " + directory);
                } else {
                    main_window.show_error_dialog("Błąd", "Nie udało się dodać katalogu: " + directory);
                }
            }
        }
    }
    
    /**
     * Obsługa kliknięcia przycisku usuwania katalogu
     */
    private void on_remove_directory_clicked() {
        var selection = custom_dirs_view.get_selection();
        TreeModel model;
        TreeIter iter;
        
        if (selection.get_selected(out model, out iter)) {
            string directory;
            model.get(iter, 0, out directory);
            
            if (backup_system.backup_manager.remove_custom_directory(directory)) {
                update_custom_dirs_list();
                var main_window = get_toplevel() as MainWindow;
                if (main_window != null) {
                    main_window.show_info_dialog("Sukces", "Usunięto katalog: " + directory);
                }
            } else {
                var main_window = get_toplevel() as MainWindow;
                if (main_window != null) {
                    main_window.show_error_dialog("Błąd", "Nie udało się usunąć katalogu: " + directory);
                }
            }
        } else {
            var main_window = get_toplevel() as MainWindow;
            if (main_window != null) {
                main_window.show_warning_dialog("Ostrzeżenie", "Wybierz katalog do usunięcia");
            }
        }
    }
    
    /**
     * Obsługa kliknięcia przycisku wykonania backupu
     */
    private void on_execute_backup_clicked() {
        // Aktualizacja konfiguracji
        backup_system.backup_manager.config.backup_packages = backup_packages_check.active;
        backup_system.backup_manager.config.backup_system_config = backup_system_config_check.active;
        backup_system.backup_manager.config.backup_desktop = backup_desktop_check.active;
        backup_system.backup_manager.config.backup_custom_dirs = backup_custom_dirs_check.active;
        
        // Wykonanie backupu w osobnym wątku
        execute_backup_button.sensitive = false;
        execute_backup_button.label = "Wykonywanie backupu...";
        
        var main_window = get_toplevel() as MainWindow;
        if (main_window != null) {
            main_window.update_status("Wykonywanie backupu...");
        }
        
        // Uruchomienie backupu w osobnym wątku
        new Thread<void*>("backup-thread", () => {
            execute_backup_in_thread();
            return null;
        });
    }
    
    /**
     * Wykonuje backup w osobnym wątku
     */
    private void execute_backup_in_thread() {
        string? backup_name = backup_name_entry.text;
        if (backup_name == null || backup_name.strip() == "") {
            backup_name = null;
        }
        
        var backup_path = backup_system.backup_manager.create_full_backup(
            backup_name,
            backup_custom_dirs_check.active
        );
        
        // Aktualizacja GUI w głównym wątku
        Idle.add(() => {
            if (backup_path != null) {
                var main_window = get_toplevel() as MainWindow;
                if (main_window != null) {
                    main_window.update_status("Backup zakończony pomyślnie: " + backup_path);
                    main_window.show_info_dialog("Sukces", 
                        "Backup zakończony pomyślnie!\nŚcieżka: " + backup_path);
                    
                    // Aktualizacja listy backupów
                    main_window.refresh_backup_list();
                }
            } else {
                var main_window = get_toplevel() as MainWindow;
                if (main_window != null) {
                    main_window.update_status("Backup zakończony niepowodzeniem");
                    main_window.show_error_dialog("Błąd", "Backup zakończony niepowodzeniem");
                }
            }
            
            // Przywrócenie przycisku
            execute_backup_button.sensitive = true;
            execute_backup_button.label = "Wykonaj backup";
            
            return false;
        });
    }
    
    /**
     * Aktualizuje listę wybranych katalogów
     */
    public void update_custom_dirs_list() {
        custom_dirs_store.clear();
        
        var directories = backup_system.backup_manager.get_custom_directories();
        foreach (var directory in directories) {
            TreeIter iter;
            custom_dirs_store.append(out iter);
            custom_dirs_store.set(iter, 0, directory);
        }
    }
}
