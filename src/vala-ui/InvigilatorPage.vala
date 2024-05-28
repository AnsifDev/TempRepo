using Gtk, Gee;

namespace Gitlink {
    class DevListRow: Adw.ActionRow {
        private Connection.Client client;

        public DevListRow() {
            add_prefix (new Image.from_icon_name ("display-symbolic"));

            var btn = new Button.with_label ("Remove");
            btn.valign = Align.CENTER;
            btn.margin_start = btn.margin_end = 6;
            btn.clicked.connect (() => disconnect_client());
            add_suffix (btn);
        }

        public void bind(Connection.Client client) {
            this.client = client;
            var name = Gitlink.Application.get_default ().get_client_name (client);
            title = name != null? name: client.inet_addr.to_string ();
            if (name != null) subtitle = client.inet_addr.to_string ();
        }

        public void disconnect_client() {
            client.end_connection ();
        }

        public signal void notify_model();
    }

    class DevListModel: RecycleViewModel {
        private Gee.ArrayList<Connection.Client> data;

        public DevListModel(Gee.ArrayList<Connection.Client> data) {
            this.data = data;
            initialize ();
        }

        public override Gtk.ListBoxRow create_list_box_row () {
            var row = new DevListRow();
            row.notify_model.connect (() => notify_data_set_changed ());
            return row;
        }
        public override void on_bind (int position, Gtk.ListBoxRow list_box_row) {
            var dev_list_row = (DevListRow) list_box_row;
            var client = data[position];
            dev_list_row.bind (client);
        }
        public override uint get_n_items () {
            return data.size;
        }

    }

    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/invigilator_page.ui")]
    class InvigilatorPage: Adw.NavigationPage {
        [GtkChild]
        private unowned Gtk.Box ip_box;

        [GtkChild]
        private unowned Gtk.ListBox dev_list_view;

        public bool hotspot_active { get; set; }
        public bool alarm_ringing { get; set; }
        public string hotspot_img { get; set; default = "/com/asiet/lab/GitLink/assets/hotspot-off.png"; }

        private Connection.Server server = Application.get_default ().server;
        private ArrayList<Connection.Client> clients = new ArrayList<Connection.Client>();
        private DevListModel model;
        private Window parent_window;

        public InvigilatorPage(Window parent_window) {
            this.parent_window = parent_window;

            Application.get_default ().bind_property("alarm_ringing", this, "alarm_ringing", GLib.BindingFlags.BIDIRECTIONAL|GLib.BindingFlags.SYNC_CREATE);
            server.connected.connect ((client) => {
                clients.add (client);
                model.notify_data_set_changed ();
                dev_list_view.visible = true;
            });

            server.disconnected.connect ((client) => {
                clients.remove (client);
                model.notify_data_set_changed ();
                dev_list_view.visible = clients.size != 0;
            });

            server.on_message_received.connect ((client, action, payload) => {
                if (action == "NAME") model.notify_data_set_changed ();
                if (action == "MOUNT") {
                    var row = (Adw.ActionRow) model.get_item(clients.index_of(client));
                    row.add_css_class("error");
                }
                
                print("%s: %s\n", action, payload);
            });

            Gitlink.Application.get_default ().bind_property ("hotspot_active", this, "hotspot_active", GLib.BindingFlags.BIDIRECTIONAL|GLib.BindingFlags.SYNC_CREATE, null, null);

            foreach (var client in Gitlink.Application.get_default ().get_connected_clients())
                clients.add (client);
            model = new DevListModel (clients);
            dev_list_view.bind_model (model, (widget) => (Widget) widget);
            dev_list_view.visible = clients.size > 0;

            foreach (var ip in server.get_ipv4 ()) {
                if (ip.has_prefix ("lo")) continue;
                var ip_raw = ip.split (" ")[1].strip();

                var bin = new Adw.Bin();
                bin.halign = bin.valign = Align.CENTER;
                bin.add_css_class ("my-small-frame");
                ip_box.append (bin);

                var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
                box.margin_start = box.margin_top = box.margin_end = box.margin_bottom = 12;
                box.halign = Align.START;
                bin.child = box;

                var label = new Label(ip_raw);
                label.halign = Align.START;
                box.append(label);

                var btn = new Button.from_icon_name ("edit-copy-symbolic");
                btn.add_css_class ("flat");
                btn.clicked.connect (() => {
                    var clipboard = get_clipboard();
                    clipboard.set_text(ip_raw);
                });
                box.append (btn);
            }
        }

        [GtkCallback]
        public bool on_state_changed(bool state) {
            hotspot_img = @"/com/asiet/lab/GitLink/assets/$(state? "hotspot": "hotspot-off").png";
            return false;
        }

        [GtkCallback]
        public void stop_alarm() {
            alarm_ringing = false;
            for (var i = 0; i < clients.size; i++) {
                var row = (Adw.ActionRow) model.get_item(i);
                row.remove_css_class("error");
            }
        }

        //  [GtkCallback]
        //  private void hotspot_on() {
        //      hotspot_active = true;
        //      //  empty = clients.size > 0;
        //      //  server.start (3000);
        //  }
    }
}