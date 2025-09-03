#!/bin/bash
# Skrypt instalacyjny dla Fedora System Backup Tool
# Autor: System Backup Tool
# Wersja: 1.0.0

set -e  # Zatrzymaj skrypt w przypadku błędu

# Kolory dla output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funkcje pomocnicze
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Sprawdzenie czy skrypt jest uruchomiony jako root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Ten skrypt musi być uruchomiony jako root (sudo)"
        print_info "Uruchom: sudo $0"
        exit 1
    fi
}

# Sprawdzenie systemu operacyjnego
check_system() {
    if [[ ! -f /etc/fedora-release ]]; then
        print_error "Ten skrypt działa tylko na systemie Fedora Linux"
        exit 1
    fi
    
    print_info "Wykryto system: $(cat /etc/fedora-release)"
}

# Sprawdzenie wymagań systemowych
check_requirements() {
    print_info "Sprawdzanie wymagań systemowych..."
    
    # Sprawdzenie Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 nie jest zainstalowany"
        print_info "Zainstaluj: sudo dnf install python3"
        exit 1
    fi
    
    # Sprawdzenie wersji Python
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
    REQUIRED_VERSION="3.8"
    
    if [[ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]]; then
        print_error "Wymagana wersja Python: $REQUIRED_VERSION+, zainstalowana: $PYTHON_VERSION"
        exit 1
    fi
    
    print_success "Python $PYTHON_VERSION - OK"
    
    # Sprawdzenie pip
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 nie jest zainstalowany"
        print_info "Zainstaluj: sudo dnf install python3-pip"
        exit 1
    fi
    
    print_success "pip3 - OK"
}

# Instalacja pakietów systemowych
install_system_packages() {
    print_info "Instalacja pakietów systemowych..."
    
    # Lista pakietów do zainstalowania
    PACKAGES=(
        "python3-pip"
        "python3-psutil"
        "python3-cryptography"
        "python3-sqlite3"
    )
    
    for package in "${PACKAGES[@]}"; do
        if ! dnf list installed "$package" &> /dev/null; then
            print_info "Instalacja $package..."
            dnf install -y "$package"
        else
            print_info "$package już zainstalowany"
        fi
    done
    
    print_success "Pakiety systemowe zainstalowane"
}

# Instalacja zależności Python
install_python_dependencies() {
    print_info "Instalacja zależności Python..."
    
    if [[ -f "requirements.txt" ]]; then
        pip3 install -r requirements.txt
        print_success "Zależności Python zainstalowane"
    else
        print_warning "Plik requirements.txt nie znaleziony, pomijam instalację zależności Python"
    fi
}

# Tworzenie katalogów systemowych
create_directories() {
    print_info "Tworzenie katalogów systemowych..."
    
    # Lista katalogów do utworzenia
    DIRECTORIES=(
        "/var/backup/fedora_system"
        "/var/lib/fedora_backup"
        "/var/log/fedora_backup"
        "/etc/fedora_backup"
        "/usr/local/bin/fedora-backup"
    )
    
    for directory in "${DIRECTORIES[@]}"; do
        if [[ ! -d "$directory" ]]; then
            mkdir -p "$directory"
            print_info "Utworzono: $directory"
        else
            print_info "Katalog już istnieje: $directory"
        fi
    done
    
    print_success "Katalogi systemowe utworzone"
}

# Ustawienie uprawnień
set_permissions() {
    print_info "Ustawianie uprawnień..."
    
    # Ustawienie właściciela i grupy
    chown -R root:root /var/backup/fedora_system
    chown -R root:root /var/lib/fedora_backup
    chown -R root:root /var/log/fedora_backup
    chown -R root:root /etc/fedora_backup
    
    # Ustawienie uprawnień
    chmod 755 /var/backup/fedora_system
    chmod 755 /var/lib/fedora_backup
    chmod 755 /var/log/fedora_backup
    chmod 755 /etc/fedora_backup
    
    # Ustawienie uprawnień do logów
    chmod 644 /var/log/fedora_backup/*
    
    print_success "Uprawnienia ustawione"
}

# Kopiowanie plików aplikacji
copy_application_files() {
    print_info "Kopiowanie plików aplikacji..."
    
    # Katalog docelowy
    INSTALL_DIR="/usr/local/bin/fedora-backup"
    
    # Lista plików do skopiowania
    FILES=(
        "backup_system.py"
        "backup_manager.py"
        "restore_manager.py"
        "cloud_integration.py"
        "scheduler.py"
        "database.py"
        "gui.py"
        "requirements.txt"
        "README.md"
    )
    
    for file in "${FILES[@]}"; do
        if [[ -f "$file" ]]; then
            cp "$file" "$INSTALL_DIR/"
            print_info "Skopiowano: $file"
        else
            print_warning "Plik nie znaleziony: $file"
        fi
    done
    
    # Ustawienie uprawnień do plików
    chmod 755 "$INSTALL_DIR"/*.py
    chmod 644 "$INSTALL_DIR"/*.txt
    chmod 644 "$INSTALL_DIR"/*.md
    
    print_success "Pliki aplikacji skopiowane"
}

# Tworzenie skryptu uruchamiającego
create_launcher_script() {
    print_info "Tworzenie skryptu uruchamiającego..."
    
    LAUNCHER_SCRIPT="/usr/local/bin/fedora-backup-tool"
    
    cat > "$LAUNCHER_SCRIPT" << 'EOF'
#!/bin/bash
# Skrypt uruchamiający Fedora System Backup Tool
# Autor: System Backup Tool

# Sprawdzenie czy Python jest dostępny
if ! command -v python3 &> /dev/null; then
    echo "Błąd: Python 3 nie jest zainstalowany"
    exit 1
fi

# Sprawdzenie czy aplikacja istnieje
APP_DIR="/usr/local/bin/fedora-backup"
MAIN_SCRIPT="$APP_DIR/backup_system.py"

if [[ ! -f "$MAIN_SCRIPT" ]]; then
    echo "Błąd: Aplikacja nie jest zainstalowana"
    echo "Uruchom skrypt instalacyjny ponownie"
    exit 1
fi

# Uruchomienie aplikacji
cd "$APP_DIR"
exec python3 "$MAIN_SCRIPT" "$@"
EOF
    
    chmod +x "$LAUNCHER_SCRIPT"
    print_success "Skrypt uruchamiający utworzony: $LAUNCHER_SCRIPT"
}

# Tworzenie pliku desktop
create_desktop_file() {
    print_info "Tworzenie pliku desktop..."
    
    DESKTOP_FILE="/usr/share/applications/fedora-backup-tool.desktop"
    
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Fedora System Backup Tool
Comment=Narzędzie do backupu i przywracania systemu Fedora
Exec=/usr/local/bin/fedora-backup-tool
Icon=system-backup
Terminal=false
Categories=System;Backup;
Keywords=backup;restore;system;fedora;
EOF
    
    chmod 644 "$DESKTOP_FILE"
    print_success "Plik desktop utworzony: $DESKTOP_FILE"
}

# Tworzenie pliku konfiguracyjnego systemd
create_systemd_files() {
    print_info "Tworzenie plików systemd..."
    
    # Plik usługi
    SERVICE_FILE="/etc/systemd/system/fedora-backup.service"
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Fedora System Backup Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/fedora-backup-tool --scheduled-backup
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF
    
    # Plik timera
    TIMER_FILE="/etc/systemd/system/fedora-backup.timer"
    
    cat > "$TIMER_FILE" << EOF
[Unit]
Description=Run Fedora System Backup
Requires=fedora-backup.service

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    chmod 644 "$SERVICE_FILE"
    chmod 644 "$TIMER_FILE"
    
    print_success "Pliki systemd utworzone"
}

# Inicjalizacja bazy danych
initialize_database() {
    print_info "Inicjalizacja bazy danych..."
    
    # Uruchomienie skryptu inicjalizacyjnego
    cd /usr/local/bin/fedora-backup
    python3 -c "
from database import DatabaseManager
try:
    db = DatabaseManager()
    print('Baza danych zainicjalizowana pomyślnie')
except Exception as e:
    print(f'Błąd inicjalizacji bazy danych: {e}')
    exit(1)
"
    
    print_success "Baza danych zainicjalizowana"
}

# Test instalacji
test_installation() {
    print_info "Testowanie instalacji..."
    
    # Sprawdzenie czy główne pliki istnieją
    MAIN_FILES=(
        "/usr/local/bin/fedora-backup/backup_system.py"
        "/usr/local/bin/fedora-backup/backup_manager.py"
        "/usr/local/bin/fedora-backup/restore_manager.py"
        "/usr/local/bin/fedora-backup/gui.py"
        "/usr/local/bin/fedora-backup-tool"
    )
    
    for file in "${MAIN_FILES[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Plik nie istnieje: $file"
            exit 1
        fi
    done
    
    # Test importu modułów
    cd /usr/local/bin/fedora-backup
    python3 -c "
try:
    import backup_manager
    import restore_manager
    import cloud_integration
    import scheduler
    import database
    import gui
    print('Wszystkie moduły importowane pomyślnie')
except Exception as e:
    print(f'Błąd importu modułów: {e}')
    exit(1)
"
    
    print_success "Test instalacji zakończony pomyślnie"
}

# Wyświetlenie informacji końcowych
show_final_info() {
    print_success "Instalacja Fedora System Backup Tool zakończona pomyślnie!"
    echo
    echo -e "${BLUE}Informacje o instalacji:${NC}"
    echo "  • Aplikacja zainstalowana w: /usr/local/bin/fedora-backup"
    echo "  • Skrypt uruchamiający: /usr/local/bin/fedora-backup-tool"
    echo "  • Plik desktop: /usr/share/applications/fedora-backup-tool.desktop"
    echo "  • Katalog backupów: /var/backup/fedora_system"
    echo "  • Baza danych: /var/lib/fedora_backup"
    echo "  • Logi: /var/log/fedora_backup"
    echo
    echo -e "${BLUE}Sposoby uruchomienia:${NC}"
    echo "  • Z menu aplikacji: Fedora System Backup Tool"
    echo "  • Z terminala: fedora-backup-tool"
    echo "  • Z terminala (z uprawnieniami root): sudo fedora-backup-tool"
    echo
    echo -e "${BLUE}Harmonogramowanie:${NC}"
    echo "  • Sprawdź status: systemctl status fedora-backup.timer"
    echo "  • Włącz automatyczne uruchamianie: systemctl enable fedora-backup.timer"
    echo "  • Uruchom timer: systemctl start fedora-backup.timer"
    echo
    echo -e "${YELLOW}Uwaga:${NC} Dla pełnej funkcjonalności uruchom aplikację z uprawnieniami root"
    echo
    echo -e "${GREEN}Dokumentacja:${NC} /usr/local/bin/fedora-backup/README.md"
}

# Główna funkcja instalacji
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Fedora System Backup Tool${NC}"
    echo -e "${BLUE}        Instalator${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    # Wykonanie kroków instalacji
    check_root
    check_system
    check_requirements
    install_system_packages
    install_python_dependencies
    create_directories
    copy_application_files
    set_permissions
    create_launcher_script
    create_desktop_file
    create_systemd_files
    initialize_database
    test_installation
    
    echo
    show_final_info
}

# Uruchomienie głównej funkcji
main "$@"
