application_id = 'com.asiet.lab.GitLink'

scalable_dir = 'hicolor' / 'scalable' / 'apps'
install_data(
  scalable_dir / ('@0@.svg').format(application_id),
  install_dir: get_option('datadir') / 'icons' / scalable_dir
)

symbolic_dir = join_paths('hicolor', 'symbolic', 'apps')
install_data(
  [
    join_paths(symbolic_dir, ('@0@-symbolic.svg').format(application_id)),
    join_paths(symbolic_dir, ('settings-symbolic.svg')),
    join_paths(symbolic_dir, ('chain-link-symbolic.svg')),
    join_paths(symbolic_dir, ('earth-symbolic.svg')),
    join_paths(symbolic_dir, ('user-trash-symbolic.svg')),
    join_paths(symbolic_dir, ('application-exit-rtl-symbolic.svg')),
    join_paths(symbolic_dir, ('view-refresh-symbolic.svg')),
    join_paths(symbolic_dir, ('error-symbolic.svg')),
    join_paths(symbolic_dir, ('warning-symbolic.svg')),
    join_paths(symbolic_dir, ('key-symbolic.svg')),
    join_paths(symbolic_dir, ('fingerprint-symbolic.svg')),
    join_paths(symbolic_dir, ('right-large-symbolic.svg')),
    join_paths(symbolic_dir, ('document-edit-symbolic.svg')),
    join_paths(symbolic_dir, ('key4-symbolic.svg')),
    join_paths(symbolic_dir, ('git-link-symbolic.svg')),
    join_paths(symbolic_dir, ('welcome-logo-symbolic.svg')),
    join_paths(symbolic_dir, ('people-symbolic.svg')),
    join_paths(symbolic_dir, ('display-symbolic.svg')),
    join_paths(symbolic_dir, ('person-symbolic.svg')),
    join_paths(symbolic_dir, ('network-server-symbolic.svg')),
    join_paths(symbolic_dir, ('edit-copy-symbolic.svg')),
    join_paths(symbolic_dir, ('user-home-symbolic.svg')),
  ],
  install_dir: get_option('datadir') / 'icons' / symbolic_dir
)
