# Fedora System Backup Tool (Vala Version)

Narzędzie do backupu i przywracania systemu Fedora Linux napisane w języku Vala z interfejsem GTK.

## Funkcjonalności

### 🔄 Backup systemu
- **Pakiety**: Backup pakietów DNF i aplikacji Flatpak
- **Konfiguracja systemu**: Backup plików `/etc` i usług systemd
- **Środowisko pulpitu**: Backup motywów, ikon, czcionek, kursorów i rozszerzeń DE
- **Sterowniki**: Backup sterowników systemu
- **Ustawienia sieci**: Backup konfiguracji NetworkManager i Bluetooth
- **Konta użytkowników**: Backup kont, kontaktów i kont email
- **Ustawienia programów**: Backup katalogu `~/.config`
- **Historia terminala**: Backup historii bash/zsh
- **Klucze SSH**: Backup kluczy SSH użytkowników

### 📁 Backup wybranych katalogów
- Dodawanie/usuwanie katalogów do backupu
- Każdy katalog backupowany osobno z zachowaniem struktury
- Automatyczne nazewnictwo z timestampem
- Metadane w formacie JSON

### 🔧 Przywracanie systemu
- Przywracanie całego systemu lub wybranych komponentów
- Przywracanie wybranych katalogów z backupu
- Automatyczne tworzenie kopii zapasowych istniejących plików
- Opcje wyboru komponentów do przywracania

### ☁️ Integracja z chmurą
- **NextCloud**: Upload/download przez WebDAV API
- **Google Drive**: Integracja z Google Drive API
- **Dropbox**: Integracja z Dropbox API
- **Lokalny backup**: Domyślna lokalizacja `/var/backup/fedora`

### ⏰ Planowanie backupów
- **systemd**: Używanie systemd timers i services
- **Częstotliwość**: Codziennie, co tydzień, co miesiąc
- **Automatyczne czyszczenie**: Usuwanie starych backupów
- **Retencja**: Konfigurowalny czas przechowywania

### 📊 Historia i logi
- Szczegółowa historia operacji backupu i przywracania
- Eksport historii do CSV
- Logi w `/var/log/fedora_backup.log`
- Baza danych SQLite z metadanymi

## Wymagania systemowe

- **System operacyjny**: Fedora Linux 35+
- **Vala**: Wersja 0.56+
- **GTK**: Wersja 3.20+
- **GLib**: Wersja 2.40+
- **SQLite**: Wersja 3.20+
- **JSON-GLib**: Wersja 1.0+

## Instalacja

### 1. Instalacja zależności systemowych

```bash
# Fedora/RHEL/CentOS
sudo dnf install vala gtk3-devel glib2-devel sqlite-devel json-glib-devel meson ninja-build

# Lub dla starszych wersji
sudo dnf install vala gtk3-devel glib2-devel sqlite-devel json-glib-devel meson ninja-build
```

### 2. Klonowanie repozytorium

```bash
git clone https://github.com/your-username/fedora-system-backup-tool.git
cd fedora-system-backup-tool
```

### 3. Kompilacja i instalacja

```bash
# Konfiguracja projektu
meson setup builddir

# Kompilacja
meson compile -C builddir

# Instalacja (wymaga uprawnień root)
sudo meson install -C builddir
```

### 4. Uruchomienie aplikacji

```bash
fedora-backup-tool
```

## Użycie

### Interfejs graficzny

Aplikacja posiada intuicyjny interfejs GTK z zakładkami:

1. **Backup**: Konfiguracja i wykonanie backupu
2. **Przywracanie**: Wybór i przywracanie z backupu
3. **Historia**: Przeglądanie historii operacji
4. **Ustawienia**: Konfiguracja aplikacji

### Dodawanie katalogów do backupu

1. Przejdź do zakładki "Backup"
2. Kliknij "Dodaj katalog"
3. Wybierz katalog z systemu plików
4. Katalog zostanie dodany do listy wybranych

### Wykonanie backupu

1. Wybierz opcje backupu (pakiety, konfiguracja, pulpity, katalogi)
2. Wprowadź nazwę backupu (opcjonalnie)
3. Kliknij "Wykonaj backup"
4. Poczekaj na zakończenie operacji

### Przywracanie z backupu

1. Przejdź do zakładki "Przywracanie"
2. Wybierz backup z listy dostępnych
3. Zaznacz komponenty do przywracania
4. Kliknij "Przywróć z wybranego backupu"

## Konfiguracja

### Pliki konfiguracyjne

- **Główna konfiguracja**: `/etc/fedora_backup/config.json`
- **Konfiguracja chmury**: `/etc/fedora_backup/cloud_config.json`
- **Konfiguracja planowania**: `/etc/fedora_backup/scheduler_config.json`

### Przykład konfiguracji głównej

```json
{
  "backup_base_path": "/var/backup/fedora",
  "log_file": "/var/log/fedora_backup.log",
  "default_backup_name": "fedora_backup",
  "compression": true,
  "encryption": false,
  "retention_days": 30
}
```

### Konfiguracja NextCloud

```json
{
  "nextcloud": {
    "enabled": true,
    "url": "https://your-nextcloud.com",
    "username": "your-username",
    "password": "your-password",
    "remote_path": "/FedoraBackups"
  }
}
```

## Planowanie backupów

### Używanie systemd

```bash
# Włączenie timera
sudo systemctl enable fedora-backup.timer

# Uruchomienie timera
sudo systemctl start fedora-backup.timer

# Sprawdzenie statusu
sudo systemctl status fedora-backup.timer

# Wyświetlenie logów
sudo journalctl -u fedora-backup.service
```

### Konfiguracja częstotliwości

Edytuj `/etc/fedora_backup/scheduler_config.json`:

```json
{
  "enabled": true,
  "method": "systemd",
  "frequency": "daily",
  "time": "02:00",
  "retention_days": 30
}
```

## Struktura plików

```
fedora-system-backup-tool/
├── src/                    # Kod źródłowy Vala
│   ├── main.vala          # Główny punkt wejścia
│   ├── backup-system.vala # Główna klasa aplikacji
│   ├── backup-manager.vala # Menedżer backupu
│   ├── restore-manager.vala # Menedżer przywracania
│   ├── cloud-integration.vala # Integracja z chmurą
│   ├── scheduler.vala     # Planowanie backupów
│   ├── database-manager.vala # Zarządzanie bazą danych
│   ├── gui.vala           # Główne okno aplikacji
│   ├── backup-window.vala # Zakładka backupu
│   ├── restore-window.vala # Zakładka przywracania
│   ├── history-window.vala # Zakładka historii
│   └── settings-window.vala # Zakładka ustawień
├── data/                  # Pliki danych aplikacji
│   ├── applications/      # Pliki .desktop
│   ├── icons/            # Ikony aplikacji
│   └── systemd/          # Pliki systemd
├── scripts/               # Skrypty pomocnicze
├── meson.build           # Plik konfiguracyjny Meson
└── README_VALA.md        # Ten plik
```

## Rozwój

### Struktura kodu

Aplikacja jest zbudowana w sposób modułowy:

- **BackupSystem**: Główna klasa koordynująca wszystkie komponenty
- **BackupManager**: Zarządzanie operacjami backupu
- **RestoreManager**: Zarządzanie operacjami przywracania
- **CloudIntegration**: Integracja z usługami chmurowymi
- **Scheduler**: Planowanie i zarządzanie backupami
- **DatabaseManager**: Zarządzanie bazą danych SQLite

### Dodawanie nowych funkcji

1. Utwórz nową klasę w katalogu `src/`
2. Dodaj klasę do `meson.build`
3. Zaimplementuj interfejs w odpowiednim oknie GUI
4. Dodaj obsługę w głównym systemie

### Kompilacja w trybie deweloperskim

```bash
# Konfiguracja z debug info
meson setup builddir --buildtype=debug

# Kompilacja
meson compile -C builddir

# Uruchomienie z debug info
G_MESSAGES_DEBUG=all ./builddir/fedora-backup-tool
```

## Rozwiązywanie problemów

### Błędy kompilacji

- Sprawdź czy wszystkie zależności są zainstalowane
- Upewnij się że używasz odpowiedniej wersji Vala
- Sprawdź logi kompilacji Meson

### Błędy runtime

- Sprawdź logi w `/var/log/fedora_backup.log`
- Uruchom aplikację z terminala aby zobaczyć błędy
- Sprawdź uprawnienia do katalogów systemowych

### Problemy z uprawnieniami

```bash
# Sprawdzenie uprawnień
ls -la /var/backup/fedora
ls -la /etc/fedora_backup

# Poprawienie uprawnień
sudo chown -R root:root /var/backup/fedora
sudo chmod 755 /var/backup/fedora
```

## Licencja

Ten projekt jest licencjonowany na licencji MIT. Zobacz plik `LICENSE` dla szczegółów.

## Wkład w projekt

1. Fork repozytorium
2. Utwórz branch dla nowej funkcji (`git checkout -b feature/amazing-feature`)
3. Commit zmian (`git commit -m 'Add amazing feature'`)
4. Push do branch (`git push origin feature/amazing-feature`)
5. Otwórz Pull Request

## Wsparcie

- **Issues**: Zgłaszaj błędy i propozycje funkcji
- **Discussions**: Dyskutuj o funkcjach i rozwoju
- **Wiki**: Dokumentacja i poradniki

## Autorzy

- **System Backup Tool** - *Początkowa implementacja*

## Podziękowania

- Społeczność Vala za świetny język programowania
- Społeczność GTK za framework GUI
- Społeczność Fedora za wspaniały system operacyjny
