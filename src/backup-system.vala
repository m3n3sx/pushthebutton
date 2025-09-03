/*
 * Fedora System Backup Tool - Główna klasa aplikacji
 * Autor: System Backup Tool
 * Wersja: 1.0.0
 * 
 * Główna klasa koordynująca wszystkie operacje backupu, przywracania i zarządzania aplikacją
 */

using Gtk;
using GLib;

public class BackupSystem : GLib.Object {
    
    // Komponenty systemu
    public BackupManager backup_manager { get; private set; }
    public RestoreManager restore_manager { get; private set; }
    public CloudIntegration cloud_integration { get; private set; }
    public Scheduler scheduler { get; private set; }
    public DatabaseManager database { get; private set; }
    
    // Główne okno aplikacji
    private MainWindow main_window;
    
    /**
     * Konstruktor głównej aplikacji backupu
     */
    public BackupSystem() {
        // Inicjalizacja komponentów
        backup_manager = new BackupManager();
        restore_manager = new RestoreManager();
        cloud_integration = new CloudIntegration();
        scheduler = new Scheduler();
        database = new DatabaseManager();
        
        // Ustawienie referencji między komponentami
        scheduler.set_backup_manager(backup_manager);
        
        // Inicjalizacja GUI
        main_window = new MainWindow(this);
        
        // Sprawdzenie uprawnień
        check_permissions();
    }
    
    /**
     * Uruchamia główną pętlę aplikacji
     */
    public void run() {
        try {
            // Wyświetlenie głównego okna
            main_window.show_all();
            
            // Uruchomienie głównej pętli GTK
            Gtk.main();
            
        } catch (Error e) {
            stderr.printf("Błąd w głównej pętli aplikacji: %s\n", e.message);
            cleanup();
        }
    }
    
    /**
     * Sprawdza czy aplikacja ma odpowiednie uprawnienia do backupu
     */
    private void check_permissions() {
        if (GLib.Environment.get_variable("SUDO_UID") == null && GLib.Environment.get_variable("SUDO_USER") == null) {
            var dialog = new MessageDialog(
                main_window,
                DialogFlags.MODAL,
                MessageType.WARNING,
                ButtonsType.OK,
                "Uwaga: Niektóre operacje backupu mogą wymagać uprawnień root.\n" +
                "Uruchom aplikację z sudo dla pełnej funkcjonalności."
            );
            dialog.run();
            dialog.destroy();
        }
    }
    
    /**
     * Czyszczenie zasobów przed zamknięciem aplikacji
     */
    public void cleanup() {
        try {
            if (database != null) {
                database.close();
            }
            if (scheduler != null) {
                scheduler.stop_scheduler();
            }
        } catch (Error e) {
            stderr.printf("Błąd podczas czyszczenia: %s\n", e.message);
        }
        
        // Zamknięcie aplikacji
        Gtk.main_quit();
    }
    
    /**
     * Obsługa sygnału zamknięcia
     */
    public void on_delete_event() {
        cleanup();
        // No return value needed for void function
    }
}
