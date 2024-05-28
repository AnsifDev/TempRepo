using Gtk, Gee;

namespace Gitlink {
    class KeyListRow: Adw.ActionRow {
        public delegate void RemoveKeyCallback(LocalKey key);
        public bool configured { get; set; default = false; }
        public bool configuring { get; set; default = false; }
        public LocalKey key { get; set; }
        public RemoveKeyCallback remove_key { get; set; }
        
        private LoginWindow parent_window;
        
        public KeyListRow(LoginWindow parent_window) {
            this.parent_window = parent_window;
            title_lines = 1;
            var prefix_img = new Gtk.Image.from_icon_name ("key-symbolic");
            prefix_img.margin_start = prefix_img.margin_end = 8;
            add_prefix (prefix_img);

            var remove = new Gtk.Button.from_icon_name ("user-trash-symbolic");
            remove.add_css_class ("error");
            remove.add_css_class ("flat");
            remove.valign = Align.CENTER;
            remove.clicked.connect (() => remove_key(key));
            add_suffix (remove);

            var go_img = new Gtk.Image.from_icon_name ("right-large-symbolic");
            go_img.margin_start = go_img.margin_end = 12;
            bind_property("configured", go_img, "visible", GLib.BindingFlags.SYNC_CREATE, null, null);
            bind_property("configuring", go_img, "visible", GLib.BindingFlags.INVERT_BOOLEAN, null, null);
            add_suffix (go_img);

            var warning_btn = new Gtk.Button.from_icon_name ("warning-symbolic");
            warning_btn.add_css_class ("warning");
            warning_btn.add_css_class ("flat");
            warning_btn.valign = Align.CENTER;
            warning_btn.tooltip_text = "Your Account doesn't have the Public Key of this Key";
            warning_btn.margin_start = warning_btn.margin_end = 3;
            bind_property("configured", warning_btn, "visible", GLib.BindingFlags.SYNC_CREATE|GLib.BindingFlags.INVERT_BOOLEAN, null, null);
            bind_property("configuring", warning_btn, "visible", GLib.BindingFlags.INVERT_BOOLEAN, null, null);
            warning_btn.clicked.connect (() => {
                var msg = new Adw.MessageDialog(parent_window, "Missing Public Key", warning_btn.tooltip_text);
                msg.add_response("ok", "OK");
                msg.present();
            });
            add_suffix (warning_btn);

            var spinner = new Gtk.Spinner ();
            spinner.valign = Align.CENTER;
            spinner.spinning = true;
            spinner.margin_start = spinner.margin_end = 12;
            bind_property("configuring", spinner, "visible", GLib.BindingFlags.SYNC_CREATE, null, null);
            add_suffix (spinner);

            activatable = true;
            title_lines = 1;
        }

        public void bind(LocalKey key) {
            this.key = key;
            tooltip_text = title = key.local_path;
            configured = key.configured;
        }
    }

    class KeyListModel: RecycleViewModel {
        private Gee.ArrayList<LocalKey> data;
        private LoginWindow parent_window;

        public KeyListModel(LoginWindow parent_window, Gee.ArrayList<LocalKey> data) {
            this.parent_window = parent_window;
            this.data = data;
            initialize ();
        }

        public override Gtk.ListBoxRow create_list_box_row () {
            return new KeyListRow(parent_window);
        }
        public override void on_bind (int position, Gtk.ListBoxRow list_box_row) {
            var key_list_row = (KeyListRow) list_box_row;
            key_list_row.bind (data[position]);
            key_list_row.remove_key = (item) => {
                var private_file = File.new_for_path(item.local_path);
                var public_file = File.new_for_path(item.local_path+".pub");

                private_file.delete();
                public_file.delete();

                var index = data.index_of(item);
                data.remove(item);
                notify_data_set_changed(index, 0, -1);
            };
        }
        public override uint get_n_items () {
            return data.size;
        }

    }

    class LocalKey {
        public string local_path { get; set; }
        public bool configured { get; set; default = false; }
    }
    
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/ssh_config_page.ui")]
    public class SSHConfigPage : Adw.NavigationPage {
        private Git.User user;
        private SSHConfiguration ssh_config;
        private LoginWindow parent_window;
        private Gee.ArrayList<LocalKey> keys = new Gee.ArrayList<LocalKey>((a, b) => a.local_path == b.local_path);
        private KeyListModel key_list_model;
        
        [GtkChild]
        private unowned Gtk.ListBox key_list_view;

        public SSHConfigPage(LoginWindow parent_window, Git.User user, SSHConfiguration ssh_config) {
            this.user = user;
            this.ssh_config = ssh_config;
            this.parent_window = parent_window;
            key_list_model = new KeyListModel(parent_window, keys);

            key_list_view.bind_model (key_list_model, (widget) => (Gtk.Widget) widget);
            key_list_view.row_activated.connect((row) => {
                var key_list_row = (KeyListRow) row;
                var local_path = key_list_row.key.local_path;
                var configured = key_list_row.key.configured;

                if (configured) configure_key_locally(local_path);
                else {
                    var msg = new Adw.MessageDialog(parent_window, "Missing Public Key", "Your Account is missing this Key's Public Key. Please upload before proceeding");
                    msg.add_response("cancel", "Cancel");
                    msg.add_response("ok", "Configure Now");
                    msg.set_response_appearance("ok", Adw.ResponseAppearance.SUGGESTED);
                    msg.response.connect((src, res) => {
                        if (res == "ok") {
                            key_list_row.configuring = true;

                            var file = File.new_for_path(@"$(key_list_row.title).pub");
                            var data_input = new DataInputStream(file.read());
                            var contents = data_input.read_line().split(" ");
                            var pubkey = contents[1];
                            var algo = contents[0];

                            var body = new HashMap<string, Value?> ();
                            body["key"] = @"$algo $pubkey";
                            body["title"] = "TestKeyGitLink";
                            Git.post_request.begin("user/keys", body, user, (src, res) => {
                                key_list_row.configuring = false;
                                var response = Git.post_request.end(res);
                                var resp_map = new JsonEngine ().parse_string_to_hashmap (response);
                                user.remote_ssh_keys.add(resp_map);
                                
                                if (response == null) {
                                    var msg2 = new Adw.MessageDialog(parent_window, "Key Upload Failed", "Unable to upload key to your account. Please try again later or try different key");
                                    msg2.add_response("ok", "OK");
                                    msg2.present();
                                } else configure_key_locally(local_path);
                            });
                        }
                    });
                    msg.present();
                }
            });
        }

        private void configure_key_locally(string local_path) {
            if (!ssh_config.has_key(@"$(user.username).github.com")) 
                ssh_config[@"$(user.username).github.com"] = new HostConfiguration.for_github(@"$(user.username).github.com");
            ssh_config[@"$(user.username).github.com"]["IdentityFile"] = local_path;

            ssh_config.save();
            parent_window.pop();
        }

        public override void shown() {
            var path = @"$(Environment.get_home_dir ())/.ssh";
            var dir = File.new_for_path (path);
            
            //Enumrator Loading
            FileEnumerator enumerator = dir.enumerate_children (
                "standard::*",
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
        
            FileInfo info = null;
            while ((info = enumerator.next_file ()) != null) {
                if (info.get_file_type () == FileType.DIRECTORY) continue;

                var filename = info.get_name ();
                if (!filename.has_suffix (".pub")) continue;
                
                var local_key = new LocalKey ();
                local_key.local_path = @"$path/$filename"[:-4];
                if (local_key in keys) continue;

                // Verifying Key Authenticity
                var file_reader = new DataInputStream(File.new_for_path(@"$(local_key.local_path).pub").read());
                var key = file_reader.read_line();

                foreach (var item in user.remote_ssh_keys) {
                    var data_map = (HashMap<string, Value?>) item;
                    var remote_key = data_map["key"].get_string();
                    
                    if (local_key.configured = key.has_prefix(remote_key)) break;
                }
                keys.add (local_key);
            }

            key_list_model.notify_data_set_changed ();
        }

        [GtkCallback]
        public void create_new() {
            var create_page = new SSHCreatePage (parent_window, user);
            parent_window.push(create_page);
        }
    }
}