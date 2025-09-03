project('fedora-system-backup-tool', 'vala', 'c',
  version : '1.0.0',
  license : 'MIT',
  meson_version : '>= 0.50.0'
)

# Zależności
glib_dep = dependency('glib-2.0', version : '>= 2.40.0')
gio_dep = dependency('gio-2.0', version : '>= 2.40.0')
gtk_dep = dependency('gtk+-3.0', version : '>= 3.20.0')
sqlite_dep = dependency('sqlite3', version : '>= 3.20.0')
json_dep = dependency('json-glib-1.0', version : '>= 1.0.0')

# Pliki źródłowe Vala
sources = [
  'src/main.vala',
  'src/logger.vala',
  'src/datetime-helper.vala',
  'src/backup-system.vala',
  'src/backup-manager.vala',
  'src/restore-manager.vala',
  'src/cloud-integration.vala',
  'src/scheduler.vala',
  'src/database-manager.vala',
  'src/gui.vala',
  'src/backup-window.vala',
  'src/restore-window.vala',
  'src/history-window.vala',
  'src/settings-window.vala'
]

# Główne pliki wykonywalne
executable('fedora-backup-tool',
  sources,
  dependencies : [glib_dep, gio_dep, gtk_dep, sqlite_dep, json_dep],
  install : true,
  install_dir : get_option('bindir')
)

# Pliki konfiguracyjne
install_data('data/fedora-backup-tool.desktop',
  install_dir : join_paths(get_option('datadir'), 'applications')
)

# Ikona aplikacji
install_data('data/icons/48x48/fedora-backup-tool.png',
  install_dir : join_paths(get_option('datadir'), 'icons', 'hicolor', '48x48', 'apps')
)

install_data('data/icons/256x256/fedora-backup-tool.png',
  install_dir : join_paths(get_option('datadir'), 'icons', 'hicolor', '256x256', 'apps')
)

# Pliki systemd
if get_option('systemd')
  systemd_dep = dependency('systemd', required : false)
  if systemd_dep.found()
    install_data('data/systemd/fedora-backup.service',
      install_dir : systemd_dep.get_pkgconfig_variable('systemdsystemunitdir')
    )
    install_data('data/systemd/fedora-backup.timer',
      install_dir : systemd_dep.get_pkgconfig_variable('systemdsystemunitdir')
    )
  endif
endif

# Opcje konfiguracyjne
meson.add_install_script('scripts/post-install.sh')
