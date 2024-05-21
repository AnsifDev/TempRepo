using Gtk;
using Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/login_window.ui")]
    public class LoginWindow : Adw.Window {
        [GtkChild]
        private unowned Adw.NavigationView nav_view;

        public signal void authenticated(Git.User user);

        public void push(Adw.NavigationPage page) { nav_view.push(page); }

        public bool pop() { return nav_view.pop(); }

        public void show_error(string description) {
            var msg = new Adw.MessageDialog(this, "Error", description);
            msg.add_response("ok", "OK");
            msg.present();
        }
        
        public LoginWindow(Window parent) {
            transient_for = parent;
            modal = true;

            push(new AuthenticationPage(this));
        }
    }
}