using Gtk;
using Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/user_config_page.ui")]
    public class UserConfigPage : Adw.NavigationPage {
        public string username { get; internal set; default = ""; }
        public string display_name { get; internal set; default = ""; }
        public string email { get; internal set; default = ""; }
        public string ssh_key { get; internal set; default = "Not Selected"; }
        public bool user_name_ok { get; internal set; default = true; }
        public bool user_email_ok { get; internal set; default = true; }
        public bool ssh_key_ok { get; internal set; default = false; }
        public bool ssh_key_warning { get; internal set; default = false; }
        public bool ssh_key_loading { get; internal set; default = true; }
        public bool confirmable { get; internal set; default = false; }

        private Git.User user;
        private SSHConfiguration ssh_config;
        private LoginWindow parent_window;
        
        public UserConfigPage(LoginWindow parent_window, Git.User user) {
            this.user = user;
            this.parent_window = parent_window;
            
            user.bind_property("username", this, "username", GLib.BindingFlags.SYNC_CREATE, null, null);
            user.bind_property("name", this, "display_name", GLib.BindingFlags.SYNC_CREATE|GLib.BindingFlags.BIDIRECTIONAL, null, null);
            user.bind_property("email", this, "email", GLib.BindingFlags.SYNC_CREATE|GLib.BindingFlags.BIDIRECTIONAL, null, null);

            ssh_config = SSHConfiguration.load();
        }

        public override void shown() {
            if (ssh_config.has_key(@"$username.github.com")) {
                ssh_key = ssh_config[@"$username.github.com"]["IdentityFile"];
                ssh_key_ok = true;
            }

            if (user.remote_ssh_keys != null) {
                ssh_key_loading = false;
                validate_keys();
            } else Git.request.begin("user/keys", user, (src, res) => {
                var response_str = Git.request.end(res);
                user.remote_ssh_keys = new JsonEngine().parse_string_to_array(response_str);

                validate_keys();
                ssh_key_loading = false;
            });
        }

        private void validate_keys() {
            confirmable = user_name_ok && user_email_ok && ssh_key_ok && !ssh_key_warning;

            if (ssh_key_ok) {
                if (ssh_key[0] == '~') ssh_key = ssh_key.replace("~", Environment.get_home_dir());
                var file_reader = new DataInputStream(File.new_for_path(@"$ssh_key.pub").read());
                var key = file_reader.read_line();
                ssh_key_warning = true;

                foreach (var item in user.remote_ssh_keys) {
                    var data_map = (HashMap<string, Value?>) item;
                    var remote_key = data_map["key"].get_string();
                    //  print("%s: %s\n", key, remote_key);

                    
                    if (!(ssh_key_warning = !key.has_prefix(remote_key))) break;
                }
            }
        }
        
        [GtkCallback]
        private void show_error(Gtk.Widget src) { parent_window.show_error(src.tooltip_text); }

        [GtkCallback]
        private void on_text_changed() {
            user_name_ok = display_name.length > 1;
            user_email_ok = "@" in email && !email.has_suffix("@") && !email.has_prefix("@");
            confirmable = user_name_ok && user_email_ok && ssh_key_ok && !ssh_key_warning && !ssh_key_loading;
        }
        
        [GtkCallback]
        private void config_ssh(Gtk.Widget src) {
            parent_window.push(new SSHConfigPage(parent_window, user, ssh_config));
        }
        
        [GtkCallback]
        private void confirm(Gtk.Widget src) {
            parent_window.authenticated(user);
            parent_window.close();
        }
    }
}