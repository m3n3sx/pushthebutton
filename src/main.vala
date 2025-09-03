/*
 * Fedora System Backup Tool - Główny plik aplikacji
 * Autor: System Backup Tool
 * Wersja: 1.0.0
 * 
 * Główna funkcja uruchamiająca aplikację backupu systemu Fedora
 */

using Gtk;
using GLib;

public class FedoraBackupTool : GLib.Object {
    
    public static int main(string[] args) {
        // Inicjalizacja GTK
        Gtk.init(ref args);
        
        try {
            // Sprawdzenie systemu operacyjnego
            if (!check_fedora_system()) {
                stderr.printf("Błąd: Ta aplikacja działa tylko na systemie Fedora Linux\n");
                return 1;
            }
            
            // Sprawdzenie uprawnień
            check_permissions();
            
            // Uruchomienie głównej aplikacji
            var app = new BackupSystem();
            app.run();
            
        } catch (Error e) {
            stderr.printf("Błąd uruchomienia aplikacji: %s\n", e.message);
            return 1;
        }
        
        return 0;
    }
    
    /**
     * Sprawdza czy aplikacja działa na systemie Fedora
     */
    private static bool check_fedora_system() {
        try {
            var file = File.new_for_path("/etc/fedora-release");
            return file.query_exists();
        } catch (Error e) {
            return false;
        }
    }
    
    /**
     * Sprawdza uprawnienia aplikacji
     */
    private static void check_permissions() {
        if (GLib.Environment.get_variable("SUDO_UID") == null && GLib.Environment.get_variable("SUDO_USER") == null) {
            var dialog = new MessageDialog(
                null,
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
}
