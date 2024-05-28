gitlink_sources = [
  'main.vala',
  'application.vala',
  'vala-ui/window.vala',
  'vala-ui/UserPage.vala',
  'vala-ui/DisplayCard.vala',
  'vala-ui/RepoCloneDialog.vala',
  'vala-helper/JsonEngine.vala',
  'vala-helper/ListModels.vala',
  'vala-helper/AccountsListModel.vala',
  'vala-helper/ReposListModel.vala',
  'vala-helper/SSHConfigurations.vala',
  'vala-helper/Connection.vala',
  'vala-helper/Bell.vala',
  'vala-git/Git.vala',
  'vala-git/GitUser.vala',
  'vala-git/GitClient.vala',
  'vala-git/GitRepo.vala',
  'vala-ui/login/AuthenticationPage.vala',
  'vala-ui/login/UserConfigPage.vala',
  'vala-ui/login/SSHConfigPage.vala',
  'vala-ui/login/LoginWindow.vala',
  'vala-ui/login/SSHCreatePage.vala',
  'vala-ui/AccountsPage.vala',
  'vala-ui/SetupPage.vala',
  'vala-ui/InvigilatorPage.vala',
  'vala-ui/ValueValidator.vala',
  'vala-ui/PreferencesDialog.vala'
]

gitlink_deps = [
  dependency('gtk4'),
  dependency('gee-0.8'),
  dependency('gio-2.0'),
  dependency('json-glib-1.0'),
  dependency('libsoup-3.0'),
  dependency('libportal-gtk4'),
  meson.get_compiler('vala').find_library('posix'),
  meson.get_compiler('vala').find_library('linux'),
  dependency('libadwaita-1', version: '>= 1.2'),
]

blueprints_src = [
    'window.blp',
    'user_page.blp',
    'display_card.blp',
    'repos_row.blp',
    'repo_clone_dialog.blp',
    'authentication_page.blp',
    'login_window.blp',
    'user_config_page.blp',
    'ssh_config_page.blp',
    'ssh_create_page.blp',
    'accounts_page.blp',
    'setup_page.blp',
    'invigilator_page.blp',
    'preferences_dialog.blp',
    'value_validator.blp',
]

blueprints_ui = []
blueprints_vala = []
blueprints_src_path = []
foreach b : blueprints_src
  blueprints_src_path += 'gtk/' + b
	blueprints_ui += b.replace('.blp', '.ui')
	blueprints_vala += b + '.vala'
endforeach


blueprints = custom_target('blueprints',
  input: blueprints_src_path,
  output: blueprints_ui,
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTDIR@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

blueprints_hack = custom_target('blueprints_hack',
	input: blueprints,
	output: blueprints_vala,
	command: [find_program('touch'), '@OUTPUT@'],
)

gitlink_sources += gnome.compile_resources('gitlink-resources',
  'gitlink.gresource.xml',
  dependencies: blueprints,
  c_name: 'gitlink'
)

executable('gitlink', gitlink_sources,
  dependencies: gitlink_deps,
  vala_args: [
  	'--target-glib=2.50',
  	'--gresourcesdir=src/',
  ],
  install: true,
  export_dynamic: true
)
