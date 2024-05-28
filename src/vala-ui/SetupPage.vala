using Gtk, Gee;

namespace Gitlink {
    enum SetupType {
        PERSONAL,
        LAB_CLIENT,
        LAB_HOST
    }

    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/setup_page.ui")]
    class SetupPage: Adw.NavigationPage {
        private SetupType type;
        private Window parent_window;
        
        public bool personal_type { get; private set; default = false; }
        public bool lab_client_type { get; private set; default = false; }
        public bool lab_host_type { get; private set; default = false; }
        public bool continuable { get; private set; default = false; }
        public bool allow_login { get; set; default = false; }
        public bool allow_multi_user { get; set; default = false; }
        public bool dev_name_ok { get; private set; default = false; }
        public bool lab_name_ok { get; private set; default = false; }
        public bool ip_addr_ok { get; private set; default = false; }
        public string dev_name { get; set; default = ""; }
        public string lab_name { get; set; default = ""; }
        public string ip_addr { get; set; default = ""; }

        private GLib.Settings settings = new GLib.Settings ("com.asiet.lab.GitLink");

        public SetupPage(Window parent_window, SetupType type) {
            this.type = type;
            this.parent_window = parent_window;
            personal_type = type == SetupType.PERSONAL;
            lab_client_type = type == SetupType.LAB_CLIENT;
            lab_host_type = type == SetupType.LAB_HOST;

            var type_name = type == SetupType.PERSONAL? "Personal": type == SetupType.LAB_CLIENT? "Lab Student": "Lab Invigilator";
            title = @"Setup As $type_name System";

            settings.bind("dev-name", this, "dev_name", GLib.SettingsBindFlags.DEFAULT);
            settings.bind("host-ip", this, "ip_addr", GLib.SettingsBindFlags.DEFAULT);
            settings.bind("lab-name", this, "lab_name", GLib.SettingsBindFlags.DEFAULT);
            settings.bind("allow-multiple-users", this, "allow_multi_user", GLib.SettingsBindFlags.DEFAULT);
        }

        [GtkCallback]
        private void on_text_change() {
            dev_name_ok = dev_name.length > 0;
            lab_name_ok = lab_name.length > 0;
            ip_addr_ok = !(":" in ip_addr) && ip_addr.split(".").length == 4;

            continuable = dev_name_ok && (type == SetupType.LAB_CLIENT ? lab_name_ok && ip_addr_ok: true);
        }

        [GtkCallback]
        public void next_page() {
            settings.set_string("app-mode", personal_type? "personal": "lab-system");
            parent_window.nav_view.pop_to_tag("welcome");
            parent_window.nav_view.push(new AccountsPage(parent_window));
        }
    }
}