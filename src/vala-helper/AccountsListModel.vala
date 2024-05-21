using Gee, Gtk;

namespace Gitlink {
    class AccountsListBoxRow: Adw.ActionRow {
        public Adw.Avatar avatar { get; default = new Adw.Avatar(48, null, true); }
        
        public AccountsListBoxRow() {
            activatable = true;
            avatar.margin_top = avatar.margin_bottom = 16;
            bind_property("title", avatar, "text", GLib.BindingFlags.SYNC_CREATE);

            add_prefix(avatar);
        }
    }

    public class AccountsListModel: RecycleViewModel {
        private ArrayList<Git.User> filtered = new ArrayList<Git.User>();
        //  private ArrayList<Value?> masked = new ArrayList<Value?>();
        private ArrayList<Git.User> data;
        
        public AccountsListModel(ArrayList<Git.User> src) { 
            data = src; 
            foreach (var item in src) filtered.add(item);
            initialize(); 
        }
    
        public void apply_search(string? text) {
            notify_data_set_changed(-1, -1, 0, text);
        }

        public new void notify_data_set_changed(int position = -1, int modified = -1, int size_difference = 0, string? text = null) {
            filtered.clear();
            foreach (var user in data) 
                if (text == null || user.name.contains(text)) filtered.add(user);
            
            base.notify_data_set_changed(position, modified, size_difference);
        }
    
        public Git.User get_data_for_row(ListBoxRow row) { return filtered[index_of_row(row)]; }
    
        public int index_of_item(Git.User user) { return filtered.index_of(user); }
    
        public override ListBoxRow create_list_box_row() { return new AccountsListBoxRow(); }
    
        public override void on_bind(int position, ListBoxRow list_box_row) {
            var user = filtered[(int) position];
            var accounts_list_box_row = list_box_row as AccountsListBoxRow;
            accounts_list_box_row.title = user.name;
            accounts_list_box_row.subtitle = user.username;
        }
    
        public override uint get_n_items () { return filtered.size; }
    }
}