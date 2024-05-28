using Gtk, Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/ssh_create_page.ui")]
    public class SSHCreatePage : Adw.NavigationPage {
        public string password { get; set; default = ""; }
        public string password_confirm { get; set; default = ""; }
        public bool password_ok { get; set; default = false; }
        public bool password_confirm_ok { get; set; default = false; }
        public bool creating { get; set; default = false; }
        public bool creatable { get; set; default = false; }
        
        private LoginWindow parent_window;
        private Git.User user;
        
        public SSHCreatePage(LoginWindow parent_window, Git.User user) {
            this.parent_window = parent_window;
            this.user = user;
        }

        private async int run_command(string cmd) {
            var t = new Thread<int>(@"command: $cmd", () => {
                var rt = Posix.system(cmd);
                Idle.add(run_command.callback);
                return rt;
            }); yield;
            return t.join();
        }

        [GtkCallback]
        private void create_new() {
            creating = true;
            creatable = false;
            run_command.begin(@"ssh-keygen -f $(Environment.get_home_dir())/.ssh/Test -N $password -t ed25519", (src, res) => {
                creatable = true;
                creating = false;
                parent_window.pop();
            });
        }

        [GtkCallback]
        private void on_text_changed() {
            password_ok = password.length > 7;
            password_confirm_ok = password == password_confirm;
            creatable = password_ok && password_confirm_ok;
        }
        
        [GtkCallback]
        private void show_error(Gtk.Widget src) { parent_window.show_error(src.tooltip_text); }
    }
}