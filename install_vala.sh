#!/bin/bash

# Fedora System Backup Tool - Vala Version - Installation Script
# Autor: System Backup Tool
# Wersja: 1.0.0
#
# Skrypt instalacyjny dla aplikacji backupu systemu Fedora napisanej w Vala

set -e

# Kolory dla wyświetlania
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Informacje o aplikacji
APP_NAME="Fedora System Backup Tool"
APP_VERSION="1.0.0"
APP_DESCRIPTION="Narzędzie do backupu i przywracania systemu Fedora Linux"

# Ścieżki instalacji
INSTALL_DIR="/usr/local"
BIN_DIR="/usr/local/bin"
DESKTOP_DIR="/usr/share/applications"
ICON_DIR="/usr/share/icons/hicolor"
SYSTEMD_DIR="/etc/systemd/system"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  $APP_NAME - Vala Version${NC}"
echo -e "${BLUE}  $APP_DESCRIPTION${NC}"
echo -e "${BLUE}  Wersja: $APP_VERSION${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Funkcja sprawdzania uprawnień root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Błąd: Ten skrypt musi być uruchomiony z uprawnieniami root${NC}"
        echo -e "${YELLOW}Uruchom: sudo $0${NC}"
        exit 1
    fi
}

# Funkcja sprawdzania systemu operacyjnego
check_system() {
    echo -e "${CYAN}Sprawdzanie systemu operacyjnego...${NC}"
    
    if [[ -f /etc/fedora-release ]]; then
        FEDORA_VERSION=$(cat /etc/fedora-release | grep -o '[0-9]\+' | head -1)
        echo -e "${GREEN}Wykryto Fedora Linux wersja $FEDORA_VERSION${NC}"
    elif [[ -f /etc/redhat-release ]]; then
        echo -e "${GREEN}Wykryto system Red Hat Enterprise Linux${NC}"
    elif [[ -f /etc/centos-release ]]; then
        echo -e "${GREEN}Wykryto CentOS${NC}"
    else
        echo -e "${RED}Błąd: Ten skrypt jest przeznaczony dla systemów Fedora/RHEL/CentOS${NC}"
        exit 1
    fi
}

# Funkcja sprawdzania wymagań
check_requirements() {
    echo -e "${CYAN}Sprawdzanie wymagań systemowych...${NC}"
    
    # Sprawdzenie Vala
    if ! command -v valac &> /dev/null; then
        echo -e "${RED}Błąd: Vala nie jest zainstalowany${NC}"
        echo -e "${YELLOW}Zainstaluj: sudo dnf install vala${NC}"
        exit 1
    fi
    
    # Sprawdzenie Meson
    if ! command -v meson &> /dev/null; then
        echo -e "${RED}Błąd: Meson nie jest zainstalowany${NC}"
        echo -e "${YELLOW}Zainstaluj: sudo dnf install meson ninja-build${NC}"
        exit 1
    fi
    
    # Sprawdzenie Ninja
    if ! command -v ninja &> /dev/null; then
        echo -e "${RED}Błąd: Ninja nie jest zainstalowany${NC}"
        echo -e "${YELLOW}Zainstaluj: sudo dnf install ninja-build${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Wszystkie wymagania są spełnione${NC}"
}

# Funkcja instalacji pakietów systemowych
install_system_packages() {
    echo -e "${CYAN}Instalowanie pakietów systemowych...${NC}"
    
    # Lista pakietów do instalacji
    PACKAGES=(
        "vala"
        "gtk3-devel"
        "glib2-devel"
        "sqlite-devel"
        "json-glib-devel"
        "meson"
        "ninja-build"
    )
    
    for package in "${PACKAGES[@]}"; do
        if ! dnf list installed "$package" &> /dev/null; then
            echo -e "${YELLOW}Instalowanie $package...${NC}"
            dnf install -y "$package"
        else
            echo -e "${GREEN}$package jest już zainstalowany${NC}"
        fi
    done
}

# Funkcja tworzenia katalogów
create_directories() {
    echo -e "${CYAN}Tworzenie katalogów systemowych...${NC}"
    
    # Katalogi backupu
    mkdir -p /var/backup/fedora
    mkdir -p /var/lib/fedora-backup
    mkdir -p /var/log
    mkdir -p /etc/fedora_backup
    
    # Katalogi aplikacji
    mkdir -p "$BIN_DIR"
    mkdir -p "$DESKTOP_DIR"
    mkdir -p "$ICON_DIR/48x48/apps"
    mkdir -p "$ICON_DIR/256x256/apps"
    
    echo -e "${GREEN}Katalogi zostały utworzone${NC}"
}

# Funkcja ustawiania uprawnień
set_permissions() {
    echo -e "${CYAN}Ustawianie uprawnień...${NC}"
    
    # Uprawnienia dla katalogów backupu
    chown -R root:root /var/backup/fedora
    chown -R root:root /var/lib/fedora-backup
    chmod 755 /var/backup/fedora
    chmod 755 /var/lib/fedora-backup
    
    # Uprawnienia dla plików log
    touch /var/log/fedora_backup.log
    chmod 644 /var/log/fedora_backup.log
    
    echo -e "${GREEN}Uprawnienia zostały ustawione${NC}"
}

# Funkcja kopiowania plików aplikacji
copy_application_files() {
    echo -e "${CYAN}Kopiowanie plików aplikacji...${NC}"
    
    # Kopiowanie pliku .desktop
    if [[ -f "data/applications/fedora-backup-tool.desktop" ]]; then
        cp data/applications/fedora-backup-tool.desktop "$DESKTOP_DIR/"
        echo -e "${GREEN}Plik .desktop został skopiowany${NC}"
    fi
    
    # Kopiowanie ikon (jeśli istnieją)
    if [[ -f "data/icons/48x48/fedora-backup-tool.png" ]]; then
        cp data/icons/48x48/fedora-backup-tool.png "$ICON_DIR/48x48/apps/"
        echo -e "${GREEN}Ikona 48x48 została skopiowana${NC}"
    fi
    
    if [[ -f "data/icons/256x256/fedora-backup-tool.png" ]]; then
        cp data/icons/256x256/fedora-backup-tool.png "$ICON_DIR/256x256/apps/"
        echo -e "${GREEN}Ikona 256x256 została skopiowana${NC}"
    fi
    
    # Kopiowanie plików systemd
    if [[ -f "data/systemd/fedora-backup.service" ]]; then
        cp data/systemd/fedora-backup.service "$SYSTEMD_DIR/"
        echo -e "${GREEN}Plik systemd service został skopiowany${NC}"
    fi
    
    if [[ -f "data/systemd/fedora-backup.timer" ]]; then
        cp data/systemd/fedora-backup.timer "$SYSTEMD_DIR/"
        echo -e "${GREEN}Plik systemd timer został skopiowany${NC}"
    fi
}

# Funkcja kompilacji aplikacji
compile_application() {
    echo -e "${CYAN}Kompilacja aplikacji...${NC}"
    
    # Sprawdzenie czy istnieje katalog build
    if [[ ! -d "builddir" ]]; then
        echo -e "${YELLOW}Konfiguracja projektu Meson...${NC}"
        meson setup builddir
    fi
    
    echo -e "${YELLOW}Kompilacja aplikacji...${NC}"
    meson compile -C builddir
    
    echo -e "${GREEN}Aplikacja została skompilowana${NC}"
}

# Funkcja instalacji aplikacji
install_application() {
    echo -e "${CYAN}Instalowanie aplikacji...${NC}"
    
    # Instalacja przez Meson
    meson install -C builddir
    
    echo -e "${GREEN}Aplikacja została zainstalowana${NC}"
}

# Funkcja tworzenia skryptu uruchamiającego
create_launcher_script() {
    echo -e "${CYAN}Tworzenie skryptu uruchamiającego...${NC}"
    
    cat > "$BIN_DIR/fedora-backup-tool" << 'EOF'
#!/bin/bash
# Fedora System Backup Tool - Launcher Script

# Sprawdzenie czy aplikacja jest zainstalowana
if [[ ! -f "/usr/bin/fedora-backup-tool" ]]; then
    echo "Błąd: Aplikacja nie jest zainstalowana"
    echo "Uruchom skrypt instalacyjny ponownie"
    exit 1
fi

# Uruchomienie aplikacji
exec /usr/bin/fedora-backup-tool "$@"
EOF
    
    chmod +x "$BIN_DIR/fedora-backup-tool"
    echo -e "${GREEN}Skrypt uruchamiający został utworzony${NC}"
}

# Funkcja konfiguracji systemd
configure_systemd() {
    echo -e "${CYAN}Konfiguracja systemd...${NC}"
    
    if [[ -f "$SYSTEMD_DIR/fedora-backup.service" ]] && [[ -f "$SYSTEMD_DIR/fedora-backup.timer" ]]; then
        # Przeładowanie systemd
        systemctl daemon-reload
        
        # Włączenie timera
        systemctl enable fedora-backup.timer
        
        echo -e "${GREEN}Systemd został skonfigurowany${NC}"
    else
        echo -e "${YELLOW}Pliki systemd nie zostały znalezione - pomijam konfigurację${NC}"
    fi
}

# Funkcja testowania instalacji
test_installation() {
    echo -e "${CYAN}Testowanie instalacji...${NC}"
    
    # Sprawdzenie czy aplikacja jest dostępna
    if command -v fedora-backup-tool &> /dev/null; then
        echo -e "${GREEN}Aplikacja jest dostępna w systemie${NC}"
    else
        echo -e "${RED}Błąd: Aplikacja nie jest dostępna${NC}"
        return 1
    fi
    
    # Sprawdzenie pliku .desktop
    if [[ -f "$DESKTOP_DIR/fedora-backup-tool.desktop" ]]; then
        echo -e "${GREEN}Plik .desktop został utworzony${NC}"
    else
        echo -e "${YELLOW}Ostrzeżenie: Plik .desktop nie został utworzony${NC}"
    fi
    
    echo -e "${GREEN}Test instalacji zakończony pomyślnie${NC}"
}

# Funkcja wyświetlania informacji końcowych
show_final_info() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}Instalacja zakończona pomyślnie!${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${CYAN}Informacje o instalacji:${NC}"
    echo -e "  • Aplikacja: $APP_NAME"
    echo -e "  • Wersja: $APP_VERSION"
    echo -e "  • Plik wykonywalny: /usr/bin/fedora-backup-tool"
    echo -e "  • Skrót: fedora-backup-tool"
    echo -e "  • Katalog backupu: /var/backup/fedora"
    echo -e "  • Konfiguracja: /etc/fedora_backup/"
    echo -e "  • Logi: /var/log/fedora_backup.log"
    echo ""
    echo -e "${CYAN}Jak uruchomić:${NC}"
    echo -e "  • Z terminala: fedora-backup-tool"
    echo -e "  • Z menu aplikacji: Fedora System Backup Tool"
    echo ""
    echo -e "${CYAN}Następne kroki:${NC}"
    echo -e "  1. Uruchom aplikację: fedora-backup-tool"
    echo -e "  2. Skonfiguruj opcje backupu w zakładce Ustawienia"
    echo -e "  3. Dodaj katalogi do backupu w zakładce Backup"
    echo -e "  4. Wykonaj pierwszy backup systemu"
    echo ""
    echo -e "${YELLOW}Uwaga: Niektóre operacje mogą wymagać uprawnień root${NC}"
    echo ""
}

# Funkcja główna
main() {
    echo -e "${BLUE}Rozpoczęcie instalacji $APP_NAME...${NC}"
    echo ""
    
    # Sprawdzenia wstępne
    check_root
    check_system
    check_requirements
    
    # Instalacja
    install_system_packages
    create_directories
    set_permissions
    copy_application_files
    compile_application
    install_application
    create_launcher_script
    configure_systemd
    
    # Testowanie
    test_installation
    
    # Informacje końcowe
    show_final_info
}

# Obsługa sygnałów
trap 'echo -e "\n${RED}Instalacja została przerwana${NC}"; exit 1' INT TERM

# Uruchomienie funkcji głównej
main "$@"
