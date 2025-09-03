/*
 * Fedora System Backup Tool - Główne okno GUI
 * Autor: System Backup Tool
 * Wersja: 1.0.0
 * 
 * Główne okno aplikacji z zakładkami i interfejsem użytkownika
 */

using Gtk;
using GLib;

public class MainWindow : Window {
    
    // Referencja do głównego systemu
    private BackupSystem backup_system;
    
    // Notebook z zakładkami
    private Notebook notebook;
    
    // Zakładki
    private BackupWindow backup_window;
    private RestoreWindow restore_window;
    private HistoryWindow history_window;
    private SettingsWindow settings_window;
    
    // Status bar
    private Label status_label;
    
    /**
     * Konstruktor głównego okna
     */
    public MainWindow(BackupSystem system) {
        backup_system = system;
        
        // Konfiguracja okna
        title = "Fedora System Backup Tool";
        window_position = WindowPosition.CENTER;
        set_default_size(900, 700);
        set_size_request(800, 600);
        
        // Ustawienie ikony
        try {
            set_icon_from_file("/usr/share/icons/hicolor/256x256/apps/system-backup.png");
        } catch (Error e) {
            // Ignoruj błędy ikony
        }
        
        // Obsługa zamknięcia okna
        delete_event.connect(() => {
            backup_system.on_delete_event();
            return false;
        });
        
        // Tworzenie interfejsu
        create_widgets();
        
        // Aktualizacja listy backupów
        refresh_backup_list();
    }
    
    /**
     * Tworzy wszystkie widgety interfejsu
     */
    private void create_widgets() {
        // Główny kontener
        var main_box = new Box(Orientation.VERTICAL, 10);
        main_box.margin = 10;
        add(main_box);
        
        // Tytuł
        var title_label = new Label("Fedora System Backup Tool");
        title_label.get_style_context().add_class("title");
        title_label.set_markup("<span size='x-large' weight='bold'>Fedora System Backup Tool</span>");
        title_label.margin_bottom = 20;
        main_box.pack_start(title_label, false, false, 0);
        
        // Notebook z zakładkami
        notebook = new Notebook();
        notebook.set_scrollable(true);
        main_box.pack_start(notebook, true, true, 0);
        
        // Tworzenie zakładek
        create_tabs();
        
        // Status bar
        status_label = new Label("Gotowy");
        status_label.get_style_context().add_class("status");
        status_label.margin_top = 10;
        main_box.pack_start(status_label, false, false, 0);
    }
    
    /**
     * Tworzy wszystkie zakładki aplikacji
     */
    private void create_tabs() {
        // Zakładka Backup
        backup_window = new BackupWindow(backup_system);
        notebook.append_page(backup_window, new Label("Backup"));
        
        // Zakładka Przywracanie
        restore_window = new RestoreWindow(backup_system);
        notebook.append_page(restore_window, new Label("Przywracanie"));
        
        // Zakładka Historia
        history_window = new HistoryWindow(backup_system);
        notebook.append_page(history_window, new Label("Historia"));
        
        // Zakładka Ustawienia
        settings_window = new SettingsWindow(backup_system);
        notebook.append_page(settings_window, new Label("Ustawienia"));
        
        // Obsługa zmiany zakładki
        notebook.switch_page.connect(on_tab_changed);
    }
    
    /**
     * Obsługa zmiany zakładki
     */
    private void on_tab_changed(Widget page, uint page_num) {
        switch (page_num) {
            case 0: // Backup
                status_label.set_text("Zakładka: Backup - Zarządzanie backupem systemu");
                break;
            case 1: // Przywracanie
                status_label.set_text("Zakładka: Przywracanie - Przywracanie z backupu");
                refresh_backup_list();
                break;
            case 2: // Historia
                status_label.set_text("Zakładka: Historia - Historia operacji");
                history_window.refresh_history();
                break;
            case 3: // Ustawienia
                status_label.set_text("Zakładka: Ustawienia - Konfiguracja aplikacji");
                break;
        }
    }
    
    /**
     * Odświeża listę dostępnych backupów
     */
    public void refresh_backup_list() {
        if (restore_window != null) {
            restore_window.refresh_backup_list();
        }
    }
    
    /**
     * Aktualizuje status aplikacji
     */
    public void update_status(string status) {
        status_label.set_text(status);
    }
    
    /**
     * Wyświetla dialog informacyjny
     */
    public void show_info_dialog(string title, string message) {
        var dialog = new MessageDialog(
            this,
            DialogFlags.MODAL,
            MessageType.INFO,
            ButtonsType.OK,
            message
        );
        dialog.title = title;
        dialog.run();
        dialog.destroy();
    }
    
    /**
     * Wyświetla dialog ostrzeżenia
     */
    public void show_warning_dialog(string title, string message) {
        var dialog = new MessageDialog(
            this,
            DialogFlags.MODAL,
            MessageType.WARNING,
            ButtonsType.OK,
            message
        );
        dialog.title = title;
        dialog.run();
        dialog.destroy();
    }
    
    /**
     * Wyświetla dialog błędu
     */
    public void show_error_dialog(string title, string message) {
        var dialog = new MessageDialog(
            this,
            DialogFlags.MODAL,
            MessageType.ERROR,
            ButtonsType.OK,
            message
        );
        dialog.title = title;
        dialog.run();
        dialog.destroy();
    }
    
    /**
     * Wyświetla dialog potwierdzenia
     */
    public bool show_confirm_dialog(string title, string message) {
        var dialog = new MessageDialog(
            this,
            DialogFlags.MODAL,
            MessageType.QUESTION,
            ButtonsType.YES_NO,
            message
        );
        dialog.title = title;
        var response = dialog.run();
        dialog.destroy();
        
        return response == ResponseType.YES;
    }
    
    /**
     * Wyświetla dialog wyboru katalogu
     */
    public string? show_folder_chooser_dialog(string title) {
        var dialog = new FileChooserDialog(
            title,
            this,
            FileChooserAction.SELECT_FOLDER,
            "_Anuluj",
            ResponseType.CANCEL,
            "_Wybierz",
            ResponseType.ACCEPT
        );
        
        string? result = null;
        if (dialog.run() == ResponseType.ACCEPT) {
            result = dialog.get_filename();
        }
        dialog.destroy();
        
        return result;
    }
    
    /**
     * Wyświetla dialog wyboru pliku do zapisu
     */
    public string? show_save_file_dialog(string title, string default_name, string[] filters) {
        var dialog = new FileChooserDialog(
            title,
            this,
            FileChooserAction.SAVE,
            "_Anuluj",
            ResponseType.CANCEL,
            "_Zapisz",
            ResponseType.ACCEPT
        );
        
        if (default_name != null) {
            dialog.set_current_name(default_name);
        }
        
        // Dodanie filtrów plików
        if (filters.length > 0) {
            var filter = new FileFilter();
            filter.set_name("Wszystkie pliki");
            filter.add_pattern("*");
            dialog.add_filter(filter);
            
            for (int i = 0; i < filters.length; i += 2) {
                if (i + 1 < filters.length) {
                    var file_filter = new FileFilter();
                    file_filter.set_name(filters[i]);
                    file_filter.add_pattern(filters[i + 1]);
                    dialog.add_filter(file_filter);
                }
            }
        }
        
        string? result = null;
        if (dialog.run() == ResponseType.ACCEPT) {
            result = dialog.get_filename();
        }
        dialog.destroy();
        
        return result;
    }
    
    /**
     * Formatuje rozmiar pliku w czytelny sposób
     */
    public static string format_file_size(int64 size) {
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
     * Formatuje datę w czytelny sposób
     */
    public static string format_date(string iso_date) {
        try {
            var date = new DateTime.from_iso8601(iso_date, null);
            if (date != null) {
                return date.format("%Y-%m-%d %H:%M:%S");
            }
        } catch (Error e) {
            // Ignoruj błędy parsowania daty
        }
        return iso_date;
    }
}
