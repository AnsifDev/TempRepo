/* window.vala
 *
 * Copyright 2023 Ansif
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Gtk;
using Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/preferences_dialog.ui")]
    public class PreferencesDialog : Adw.PreferencesDialog {
        private GLib.Settings settings = new GLib.Settings ("com.asiet.lab.GitLink");
        
        public bool personal_type { get; private set; default = false; }
        public bool lab_client_type { get; private set; default = false; }
        public bool lab_host_type { get; private set; default = false; }
        public bool allow_multi_user { get; set; default = false; }
        public string dev_name { get; set; default = ""; }
        public string lab_name { get; set; default = ""; }
        public string ip_addr { get; set; default = ""; }
        public string app_mode { get; set; default = ""; }
        public string app_mode_string { get; private set; default = "Loading App Mode"; }

        public PreferencesDialog () {
            personal_type = settings.get_string("app-mode") == "personal";
            lab_client_type = settings.get_string("app-mode") == "lab-system";
            lab_host_type = settings.get_string("app-mode") == "lab-host";

            settings.bind("dev-name", this, "dev_name", GLib.SettingsBindFlags.DEFAULT);
            settings.bind("host-ip", this, "ip_addr", GLib.SettingsBindFlags.DEFAULT);
            settings.bind("lab-name", this, "lab_name", GLib.SettingsBindFlags.DEFAULT);
            settings.bind("allow-multiple-users", this, "allow_multi_user", GLib.SettingsBindFlags.DEFAULT);
            settings.bind("app-mode", this, "app_mode", GLib.SettingsBindFlags.DEFAULT);

            app_mode_string = app_mode == "personal"? "Personal System": app_mode == "lab-system"? "Lab System": "Invigilator System";
        }

        [GtkCallback]
        public void change_lab_name () {
            var value_validator = new ValueValidator ("Change Lab Name", "Change the lab name which this system is placed", lab_name);
            value_validator.error = "Lab name must contain atleast 1 character";
            value_validator.on_value_changed.connect ((value) => { value_validator.valid = value.length > 0; });
            value_validator.response.connect ((response) => { if (response == "confirm") lab_name = value_validator.value; });
            value_validator.present (this);
        }

        [GtkCallback]
        public void change_dev_name () {
            var value_validator = new ValueValidator ("Change Device Name", "Change the device name of this system", dev_name);
            value_validator.error = "Device name must contain atleast 1 character";
            value_validator.on_value_changed.connect ((value) => { value_validator.valid = value.length > 0; });
            value_validator.response.connect ((response) => {
                if (response == "confirm") {
                    dev_name = value_validator.value;
                    var app = Application.get_default ();
                    if (app.client != null) app.client.send_message ("NAME", dev_name);
                }
            });
            value_validator.present (this);
        }

        [GtkCallback]
        public void change_host_ip () {
            var value_validator = new ValueValidator ("Change Server IP Address", "Change the Host IP address", ip_addr);
            value_validator.error = "Invalid IPv4 address";
            value_validator.on_value_changed.connect ((value) => { value_validator.valid = !(":" in value) && value.split(".").length == 4; });
            value_validator.response.connect ((response) => {
                if (response == "confirm") {
                    ip_addr = value_validator.value;
                    var app = Application.get_default ();
                    app.disconnect_from_server ();
                    app.connect_to_server.begin ((src, res) => {
                        if (!app.connect_to_server.end(res)) {
                            var msg = new Adw.AlertDialog("Server Connection Failed", @"Connection to the server $(settings.get_string("host-ip")) is failed. Please check the IP Address or make sure you turned the hotspot on in Server GitLink App");
                            msg.add_response("ok", "OK");
                            msg.present(this);
                        }
                    });
                }
            });
            value_validator.present (this);
        }

        [GtkCallback]
        public void reset_app_mode () {
            var msg = new Adw.AlertDialog("Reset App Configuration?", @"You are going to change the app mode. This may cause data loss. Changes takes effect on next launch");
            msg.add_response("cancel", "Cancel");
            msg.add_response("ok", "Reset & Restart Now");
            msg.set_response_appearance ("ok", Adw.ResponseAppearance.DESTRUCTIVE);
            msg.close_response = "cancel";
            msg.response.connect ((response) => {
                if (response == "ok") {
                    app_mode = "unknown";
                    var app = Application.get_default ();
                    app.disconnect_from_server ();
                    app.hotspot_active = false;
                    close ();
                    app.hold();
                    app.active_window.close ();
                    var win = new Window(app);
                    win.present ();
                    app.release();
                }
            });
            msg.present(this);
        }
    }
}
 