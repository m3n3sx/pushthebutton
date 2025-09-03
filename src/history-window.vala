/*
 * Fedora System Backup Tool - Zakładka Historia
 * Autor: System Backup Tool
 * Wersja: 1.0.0
 * 
 * Zakładka wyświetlająca historię operacji backupu i przywracania
 */

using Gtk;
using GLib;

public class HistoryWindow : Box {
    
    // Referencja do głównego systemu
    private BackupSystem backup_system;
    
    // Widok historii operacji
    private Gtk.ListStore history_store;
    private TreeView history_view;
    
    /**
     * Konstruktor zakładki Historia
     */
    public HistoryWindow(BackupSystem system) {
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
        // Tytuł sekcji
        var title_label = new Label("Historia operacji backupu i przywracania");
        title_label.get_style_context().add_class("title");
        title_label.set_markup("<span size='large' weight='bold'>Historia operacji</span>");
        title_label.margin_bottom = 10;
        pack_start(title_label, false, false, 0);
        
        // Lista historii
        create_history_list();
        
        // Przyciski akcji
        create_action_buttons();
    }
    
    /**
     * Tworzy listę historii operacji
     */
    private void create_history_list() {
        var history_frame = new Frame("Historia operacji");
        pack_start(history_frame, true, true, 0);
        
        var history_box = new Box(Orientation.VERTICAL, 5);
        history_box.margin = 10;
        history_frame.add(history_box);
        
        // Model danych (data, typ, status, szczegóły)
        history_store = new Gtk.ListStore(4, typeof(string), typeof(string), typeof(string), typeof(string));
        
        // Widok drzewa
        history_view = new TreeView.with_model(history_store);
        history_view.headers_visible = true;
        history_view.set_size_request(-1, 300);
        
        // Kolumna daty
        var date_column = new TreeViewColumn();
        var date_cell = new CellRendererText();
        date_column.pack_start(date_cell, true);
        date_column.add_attribute(date_cell, "text", 0);
        date_column.title = "Data i czas";
        date_column.expand = false;
        history_view.append_column(date_column);
        
        // Kolumna typu operacji
        var type_column = new TreeViewColumn();
        var type_cell = new CellRendererText();
        type_column.pack_start(type_cell, true);
        type_column.add_attribute(type_cell, "text", 1);
        type_column.title = "Typ operacji";
        type_column.expand = false;
        history_view.append_column(type_column);
        
        // Kolumna statusu
        var status_column = new TreeViewColumn();
        var status_cell = new CellRendererText();
        status_column.pack_start(status_cell, true);
        status_column.add_attribute(status_cell, "text", 2);
        status_column.title = "Status";
        status_column.expand = false;
        history_view.append_column(status_column);
        
        // Kolumna szczegółów
        var details_column = new TreeViewColumn();
        var details_cell = new CellRendererText();
        details_column.pack_start(details_cell, true);
        details_column.add_attribute(details_cell, "text", 3);
        details_column.title = "Szczegóły";
        details_column.expand = true;
        history_view.append_column(details_column);
        
        // Scrollbar
        var scrolled_window = new ScrolledWindow(null, null);
        scrolled_window.add(history_view);
        scrolled_window.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        
        history_box.pack_start(scrolled_window, true, true, 0);
    }
    
    /**
     * Tworzy przyciski akcji
     */
    private void create_action_buttons() {
        var buttons_box = new Box(Orientation.HORIZONTAL, 5);
        buttons_box.margin_top = 10;
        pack_start(buttons_box, false, false, 0);
        
        // Przycisk odświeżania historii
        var refresh_button = new Button.with_label("Odśwież historię");
        refresh_button.clicked.connect(on_refresh_history_clicked);
        buttons_box.pack_start(refresh_button, false, false, 0);
        
        // Przycisk eksportu historii
        var export_button = new Button.with_label("Eksportuj historię");
        export_button.clicked.connect(on_export_history_clicked);
        buttons_box.pack_start(export_button, false, false, 0);
        
        // Przycisk czyszczenia historii
        var clear_button = new Button.with_label("Wyczyść historię");
        clear_button.clicked.connect(on_clear_history_clicked);
        buttons_box.pack_start(clear_button, false, false, 0);
    }
    
    /**
     * Obsługa kliknięcia przycisku odświeżania historii
     */
    private void on_refresh_history_clicked() {
        refresh_history();
    }
    
    /**
     * Obsługa kliknięcia przycisku eksportu historii
     */
    private void on_export_history_clicked() {
        var main_window = get_toplevel() as MainWindow;
        if (main_window != null) {
            var filename = main_window.show_save_file_dialog(
                "Eksportuj historię",
                "historia_backupu.csv",
                {"CSV", "*.csv", "Wszystkie pliki", "*"}
            );
            
            if (filename != null) {
                export_history_to_csv(filename);
            }
        }
    }
    
    /**
     * Obsługa kliknięcia przycisku czyszczenia historii
     */
    private void on_clear_history_clicked() {
        var main_window = get_toplevel() as MainWindow;
        if (main_window != null) {
            if (main_window.show_confirm_dialog("Potwierdzenie", 
                "Czy na pewno chcesz wyczyścić całą historię operacji?")) {
                
                clear_history();
            }
        }
    }
    
    /**
     * Odświeża historię operacji
     */
    public void refresh_history() {
        history_store.clear();
        
        try {
            // Odczytanie historii z pliku log
            var log_file = File.new_for_path("/var/log/fedora_backup.log");
            if (log_file.query_exists()) {
                var input_stream = log_file.read();
                var data_input_stream = new DataInputStream(input_stream);
                
                string? line;
                var operations = new List<OperationRecord>();
                
                // Odczytanie wszystkich linii
                while ((line = data_input_stream.read_line()) != null) {
                    if (line.strip() != "") {
                        var record = parse_log_line(line);
                        if (record != null) {
                            operations.append(record);
                        }
                    }
                }
                
                input_stream.close();
                
                // Sortowanie po dacie (od najnowszych)
                operations.sort((a, b) => {
                    if (a.timestamp.compare(b.timestamp) > 0) return -1;
                    if (a.timestamp.compare(b.timestamp) < 0) return 1;
                    return 0;
                });
                
                // Dodanie do widoku
                foreach (var record in operations) {
                    TreeIter iter;
                    history_store.append(out iter);
                    history_store.set(iter,
                        0, record.formatted_timestamp,
                        1, record.operation_type,
                        2, record.status,
                        3, record.details
                    );
                }
            }
        } catch (Error e) {
            var main_window = get_toplevel() as MainWindow;
            if (main_window != null) {
                main_window.show_error_dialog("Błąd", "Nie udało się odświeżyć historii: " + e.message);
            }
        }
    }
    
    /**
     * Parsuje linię logu i tworzy rekord operacji
     */
    private OperationRecord? parse_log_line(string line) {
        try {
            // Format: YYYY-MM-DD HH:MM:SS - LEVEL - message
            var parts = line.split(" - ", 3);
            if (parts.length >= 3) {
                var timestamp_str = parts[0];
                var level = parts[1];
                var message = parts[2];
                
                // Parsowanie timestamp
                var timestamp = new DateTime.from_iso8601(timestamp_str, null);
                if (timestamp == null) {
                    return null;
                }
                
                // Określenie typu operacji
                string operation_type = "Inne";
                if (message.contains("backup")) {
                    operation_type = "Backup";
                } else if (message.contains("restore") || message.contains("przywracan")) {
                    operation_type = "Przywracanie";
                } else if (message.contains("dodano") || message.contains("usunięto")) {
                    operation_type = "Zarządzanie";
                }
                
                // Określenie statusu
                string status = "Informacja";
                if (level == "ERROR") {
                    status = "Błąd";
                } else if (level == "WARNING") {
                    status = "Ostrzeżenie";
                } else if (level == "INFO") {
                    status = "Sukces";
                }
                
                return new OperationRecord(timestamp, operation_type, status, message);
            }
        } catch (Error e) {
            // Ignoruj błędy parsowania
        }
        
        return null;
    }
    
    /**
     * Eksportuje historię do pliku CSV
     */
    private void export_history_to_csv(string filename) {
        try {
            var file = File.new_for_path(filename);
            var output_stream = file.replace(null, false, FileCreateFlags.NONE);
            var data_output_stream = new DataOutputStream(output_stream);
            
            // Nagłówek CSV
            data_output_stream.put_string("Data i czas,Typ operacji,Status,Szczegóły\n");
            
            // Dane
            TreeIter iter;
            bool valid = history_store.get_iter_first(out iter);
            while (valid) {
                string timestamp, type, status, details;
                history_store.get(iter, 0, out timestamp, 1, out type, 2, out status, 3, out details);
                
                // Escapowanie cudzysłowów w CSV
                var escaped_details = details.replace("\"", "\"\"");
                data_output_stream.put_string("\"%s\",\"%s\",\"%s\",\"%s\"\n".printf(
                    timestamp, type, status, escaped_details
                ));
                
                valid = history_store.iter_next(ref iter);
            }
            
            data_output_stream.close();
            
            var main_window = get_toplevel() as MainWindow;
            if (main_window != null) {
                main_window.show_info_dialog("Sukces", "Historia została wyeksportowana do: " + filename);
            }
            
        } catch (Error e) {
            var main_window = get_toplevel() as MainWindow;
            if (main_window != null) {
                main_window.show_error_dialog("Błąd", "Nie udało się wyeksportować historii: " + e.message);
            }
        }
    }
    
    /**
     * Czyści historię operacji
     */
    private void clear_history() {
        try {
            // Czyszczenie widoku
            history_store.clear();
            
            // Czyszczenie pliku log
            var log_file = File.new_for_path("/var/log/fedora_backup.log");
            if (log_file.query_exists()) {
                log_file.delete();
            }
            
            var main_window = get_toplevel() as MainWindow;
            if (main_window != null) {
                main_window.show_info_dialog("Sukces", "Historia została wyczyszczona");
            }
            
        } catch (Error e) {
            var main_window = get_toplevel() as MainWindow;
            if (main_window != null) {
                main_window.show_error_dialog("Błąd", "Nie udało się wyczyścić historii: " + e.message);
            }
        }
    }
}

/**
 * Klasa reprezentująca rekord operacji
 */
public class OperationRecord : GLib.Object {
    public DateTime timestamp { get; private set; }
    public string operation_type { get; private set; }
    public string status { get; private set; }
    public string details { get; private set; }
    public string formatted_timestamp { get; private set; }
    
    public OperationRecord(DateTime ts, string type, string st, string det) {
        timestamp = ts;
        operation_type = type;
        status = st;
        details = det;
        formatted_timestamp = ts.format("%Y-%m-%d %H:%M:%S");
    }
}
