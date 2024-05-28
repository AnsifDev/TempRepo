using Gtk;
using Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/authentication_page.ui")]
    public class AuthenticationPage : Adw.NavigationPage {
        [GtkChild]
        private unowned Button btn_authorize;

        [GtkChild]
        private unowned Adw.ToastOverlay toast_overlay;

        public string? user_code { get; private set; default = "OCSD-12DE"; }
        public bool polling { get; set; default = false; }
        public string auth_label { get; set; default = ""; }

        private string? device_code = null;
        private int64? interval = null;
        private int64? expire = null;
        private LoginWindow parent_window;
        
        public AuthenticationPage(LoginWindow parent_window) {
            this.parent_window = parent_window;
            //  btn_authorize.sensitive = true;
            auth_label = "Setting up";
            
            Git.get_login_code.begin((src, res) => {
                try {
                    var response_map = Git.get_login_code.end(res);
                    device_code = (string) response_map["device_code"];
                    user_code = (string) response_map["user_code"];
                    interval = (int64) response_map["interval"];
                    expire = (int64) response_map["expires_in"];

                    btn_authorize.sensitive = true;
                    auth_label = "Authorize";
                } catch (Error e) { print(e.message); }
            });
        }

        [GtkCallback]
        private void copy_code() {
            var clipboard = get_clipboard();
            clipboard.set_text(user_code);
            var toast = new Adw.Toast(@"User Code $user_code Copied");
            toast_overlay.add_toast(toast);
        }

        private async Git.User authenticate() throws Error {
            var client = Git.Client.get_default();

            var user = yield client.authenticate(device_code, (int) expire, (int) interval);
            //  var user = client.load_local_users()[0];
            
            var resp = yield Git.request("user/keys", user);
            user.remote_ssh_keys = new JsonEngine().parse_string_to_array(resp);
            return user;
        }

        [GtkCallback]
        private void authorize() {
            var launcher = new UriLauncher("https://github.com/login/device");
            launcher.launch.begin(parent_window, null);
            if (!polling) {
                polling = true;
                authenticate.begin((src, res) => {
                    try {
                        var user = authenticate.end(res);

                        parent_window.push(new UserConfigPage(parent_window, user));
                    } catch (Error e) {
                        var msg = new Adw.MessageDialog(parent_window, "Something Wrong", "Login Failed due some unexpected error");
                        msg.add_response("ok", "OK");
                        msg.present();
                    }
                });
            }
        }
    }
}