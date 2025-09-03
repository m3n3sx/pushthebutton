# Fedora System Backup Tool - Wersja Vala

## 🎯 Opis projektu

Fedora System Backup Tool to zaawansowana aplikacja do backupu i przywracania systemu Fedora Linux napisana w języku **Vala** z interfejsem graficznym **GTK3**. Aplikacja zapewnia kompleksowe rozwiązanie do zarządzania backupami systemu, w tym pakietów, konfiguracji, środowiska pulpitu i wybranych przez użytkownika katalogów.

## ✨ Kluczowe funkcje

### 🔄 Backup systemu
- **Pakietów DNF i Flatpak** - lista zainstalowanych pakietów i repozytoriów
- **Konfiguracji systemu** - pliki /etc, usługi systemd
- **Środowiska pulpitu** - motywy, ikony, czcionki, kursory
- **Wybranych katalogów** - możliwość dodawania/usuwania folderów przez filedialog

### 🔧 Przywracanie systemu
- **Pełne przywracanie** - cały system lub wybrane komponenty
- **Selektywne przywracanie** - pakiety, konfiguracja, środowisko pulpitu
- **Przywracanie katalogów** - analogiczne do backupu z zachowaniem struktury

### ☁️ Integracja z chmurą
- **NextCloud** - natywna integracja z WebDAV API
- **Google Drive** - integracja przez Google Drive API
- **Dropbox** - integracja przez Dropbox API
- **Automatyczny upload** - po wykonaniu backupu

### ⏰ Harmonogramowanie
- **Systemd** - natywne harmonogramowanie przez systemd timers
- **Python scheduler** - alternatywne harmonogramowanie w Python
- **Elastyczne opcje** - codziennie, co tydzień, co miesiąc

### 📊 Historia i statystyki
- **Baza SQLite** - historia operacji backupu i przywracania
- **Eksport danych** - eksport historii do formatu CSV
- **Statystyki** - rozmiary backupów, liczba operacji

## 🛠️ Wymagania systemowe

### System operacyjny
- **Fedora Linux** 35+ (lub kompatybilne dystrybucje)
- **Kernel** 5.0+
- **Systemd** jako system init

### Zależności systemowe
```bash
# Podstawowe pakiety
sudo dnf install vala glib2-devel gtk3-devel sqlite-devel json-glib-devel

# Opcjonalne - dla integracji z chmurą
sudo dnf install nextcloud-client
```

### Zależności Python (dla niektórych funkcji)
```bash
pip3 install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client dropbox
```

## 🚀 Instalacja

### 1. Klonowanie repozytorium
```bash
git clone https://github.com/your-username/fedora-system-backup-tool.git
cd fedora-system-backup-tool
```

### 2. Kompilacja z Meson
```bash
# Tworzenie katalogu build
mkdir build && cd build

# Konfiguracja
meson configure

# Kompilacja
ninja

# Instalacja
sudo ninja install
```

### 3. Alternatywna instalacja z CMake
```bash
mkdir build && cd build
cmake ..
make
sudo make install
```

## 📁 Struktura projektu

```
fedora-system-backup-tool/
├── src/                           # Kod źródłowy Vala
│   ├── main.vala                  # Główny plik aplikacji
│   ├── backup-system.vala         # Główna klasa systemu
│   ├── backup-manager.vala        # Zarządzanie backupem
│   ├── restore-manager.vala       # Zarządzanie przywracaniem
│   ├── cloud-integration.vala     # Integracja z chmurą
│   ├── scheduler.vala             # Harmonogramowanie
│   ├── database-manager.vala      # Baza danych SQLite
│   ├── gui.vala                   # Główne okno aplikacji
│   ├── backup-window.vala         # Zakładka Backup
│   ├── restore-window.vala        # Zakładka Przywracanie
│   ├── history-window.vala        # Zakładka Historia
│   └── settings-window.vala       # Zakładka Ustawienia
├── data/                          # Pliki konfiguracyjne
│   ├── fedora-backup-tool.desktop # Plik .desktop
│   ├── icons/                     # Ikony aplikacji
│   └── systemd/                   # Pliki systemd
├── scripts/                       # Skrypty pomocnicze
├── meson.build                    # Konfiguracja Meson
├── CMakeLists.txt                 # Konfiguracja CMake
└── README.md                      # Dokumentacja
```

## 🎮 Użycie

### Uruchomienie aplikacji
```bash
# Z menu aplikacji
fedora-backup-tool

# Lub bezpośrednio
/usr/local/bin/fedora-backup-tool

# Z uprawnieniami root (dla pełnej funkcjonalności)
sudo fedora-backup-tool
```

### Interfejs użytkownika

#### 🔄 Zakładka Backup
- ✅ Checkboxy opcji backupu
- 📁 **Przycisk "Dodaj katalog"** - otwiera filedialog
- 📋 **Lista wybranych katalogów** z opcją usuwania
- 🎯 **Checkbox "Backup wybranych katalogów"**
- 🏷️ Pole nazwy backupu
- ▶️ Przycisk wykonania backupu

#### 🔧 Zakładka Przywracanie
- 📋 Lista dostępnych backupów
- ✅ Opcje przywracania komponentów
- 🔄 Przycisk przywracania
- 🗑️ Usuwanie backupów

#### 📊 Zakładka Historia
- 📊 Treeview z historią operacji
- 📤 Eksport do CSV
- 🔄 Odświeżanie danych

#### ⚙️ Zakładka Ustawienia
- ⏰ Konfiguracja harmonogramowania
- ☁️ Ustawienia integracji z chmurą
- 💾 Zapisywanie konfiguracji

## 🔧 Konfiguracja

### Pliki konfiguracyjne
- `/etc/fedora_backup/backup_config.json` - konfiguracja backupu
- `/etc/fedora_backup/scheduler_config.json` - konfiguracja harmonogramowania
- `/etc/fedora_backup/cloud_config.json` - konfiguracja integracji z chmurą
- `/etc/fedora_backup/settings.json` - ogólne ustawienia aplikacji

### Przykład konfiguracji backupu
```json
{
  "backup_packages": true,
  "backup_system_config": true,
  "backup_desktop": true,
  "backup_drivers": true,
  "backup_users": true,
  "backup_custom_dirs": true
}
```

### Przykład konfiguracji harmonogramowania
```json
{
  "enabled": true,
  "method": "systemd",
  "frequency": "daily",
  "hour": 2,
  "retention_days": 30,
  "upload_to_cloud": false
}
```

## ☁️ Integracja z chmurą

### NextCloud
```json
{
  "nextcloud_enabled": true,
  "nextcloud_server": "https://nextcloud.example.com",
  "nextcloud_username": "your_username",
  "nextcloud_password": "your_password"
}
```

### Google Drive
```json
{
  "google_drive_enabled": true,
  "google_drive_client_id": "your_client_id",
  "google_drive_client_secret": "your_client_secret",
  "google_drive_token": "your_oauth_token"
}
```

### Dropbox
```json
{
  "dropbox_enabled": true,
  "dropbox_access_token": "your_access_token"
}
```

## ⏰ Harmonogramowanie

### Systemd (zalecane)
```bash
# Sprawdzenie statusu
systemctl status fedora-backup.timer

# Włączenie/wyłączenie
sudo systemctl enable fedora-backup.timer
sudo systemctl disable fedora-backup.timer

# Uruchomienie/zatrzymanie
sudo systemctl start fedora-backup.timer
sudo systemctl stop fedora-backup.timer
```

### Python Scheduler
- Alternatywa dla systemd
- Działa w tle aplikacji
- Mniej precyzyjne niż systemd

## 🗄️ Baza danych

### Struktura bazy SQLite
- **backups** - rekordy backupów
- **restore_operations** - operacje przywracania
- **operation_logs** - logi operacji
- **backup_statistics** - statystyki backupów

### Lokalizacja
- `/var/lib/fedora_backup/backup_history.db`

### Backup bazy danych
```bash
# Kopiowanie bazy danych
sudo cp /var/lib/fedora_backup/backup_history.db /backup/

# Przywracanie bazy danych
sudo cp /backup/backup_history.db /var/lib/fedora_backup/
```

## 🐛 Rozwiązywanie problemów

### Logi aplikacji
```bash
# Główny log aplikacji
sudo tail -f /var/log/fedora_backup.log

# Log systemd (dla harmonogramowania)
sudo journalctl -u fedora-backup.service -f
```

### Sprawdzanie uprawnień
```bash
# Sprawdzenie uprawnień do katalogów
ls -la /var/backup/fedora_system/
ls -la /var/lib/fedora_backup/
ls -la /etc/fedora_backup/

# Poprawka uprawnień
sudo chown -R root:root /var/backup/fedora_system/
sudo chmod -R 755 /var/backup/fedora_system/
```

### Testowanie połączeń
```bash
# Test połączenia z chmurą
fedora-backup-tool --test-cloud

# Test harmonogramowania
fedora-backup-tool --test-scheduler
```

## 🔒 Bezpieczeństwo

### Uprawnienia
- Aplikacja wymaga uprawnień root dla niektórych operacji
- Pliki konfiguracyjne są chronione uprawnieniami 600
- Logi są zapisywane z odpowiednimi uprawnieniami

### Szyfrowanie
- Hasła w plikach konfiguracyjnych są przechowywane w postaci zwykłego tekstu
- Zalecane użycie systemu zarządzania sekretami (np. kwallet)

## 🚀 Rozszerzanie funkcjonalności

### Dodawanie nowych dostawców chmury
1. Utwórz nową klasę w `src/cloud-integration.vala`
2. Dodaj metody upload/download
3. Zaktualizuj `CloudConfig` i `CloudIntegration`
4. Dodaj opcje w GUI

### Dodawanie nowych komponentów backupu
1. Dodaj nowe pola w `BackupConfig`
2. Zaimplementuj metody w `BackupManager`
3. Zaktualizuj GUI w `backup-window.vala`
4. Dodaj obsługę w `RestoreManager`

## 📝 Licencja

Ten projekt jest licencjonowany na licencji MIT - zobacz plik [LICENSE](LICENSE) dla szczegółów.

## 🤝 Współpraca

### Zgłaszanie błędów
- Użyj systemu Issues w GitHub
- Opisz problem szczegółowo
- Dołącz logi i informacje o systemie

### Proponowanie funkcji
- Utwórz Issue z etykietą "enhancement"
- Opisz proponowaną funkcjonalność
- Przedyskutuj z zespołem

### Pull Requests
- Fork repozytorium
- Utwórz branch dla funkcji
- Przetestuj zmiany
- Utwórz Pull Request

## 📞 Wsparcie

### Dokumentacja
- [Dokumentacja Vala](https://valadoc.org/)
- [GTK3 Documentation](https://developer.gnome.org/gtk3/)
- [GLib Reference Manual](https://developer.gnome.org/glib/)

### Społeczność
- [Fedora Forums](https://forums.fedoraforum.org/)
- [Vala Community](https://wiki.gnome.org/Projects/Vala)
- [GTK Community](https://www.gtk.org/community/)

## 📈 Roadmap

### Wersja 1.1.0
- [ ] Pełna integracja z chmurą
- [ ] Szyfrowanie backupów
- [ ] Kompresja backupów
- [ ] Backup baz danych

### Wersja 1.2.0
- [ ] Backup maszyn wirtualnych
- [ ] Backup kontenerów Docker
- [ ] Backup systemów plików
- [ ] Backup bootloaderów

### Wersja 2.0.0
- [ ] Interfejs webowy
- [ ] API REST
- [ ] Współpraca wielu maszyn
- [ ] Automatyczne testy backupów

---

**Fedora System Backup Tool** - Profesjonalne narzędzie do backupu systemu Fedora Linux napisane w Vala z interfejsem GTK3.
