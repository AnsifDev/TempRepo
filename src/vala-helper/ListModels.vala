using Gtk, Gee;

namespace Gitlink {
    public abstract class RecycleViewModel: GLib.ListModel, Object {
        private ArrayList<ListBoxRow> active_list_box_rows = new ArrayList<ListBoxRow>();
        private ArrayList<ListBoxRow> trashed_list_box_rows = new ArrayList<ListBoxRow>();
        private int previous_size = -1;

        protected void initialize() {
            previous_size = (int) get_n_items();
            for (int i = 0; i < previous_size; i++) {
                var list_box_row = create_list_box_row();
                active_list_box_rows.insert(i, list_box_row);
                on_bind(i, list_box_row);
            }
        }

        public abstract ListBoxRow create_list_box_row();

        public abstract void on_bind(int position, ListBoxRow list_box_row);

        public virtual void on_unbind(ListBoxRow list_box_row) {}

        public void notify_data_set_changed(int position = -1, int modified = -1, int size_difference = 0) {
            if (size_difference != 0) assert (modified > -1);

            //Initializing all variables to a valid state
            int size = (int) get_n_items ();
            if (modified == -1) {
                if (position != -1) modified = 1;
                else modified = previous_size < size ? previous_size: size;
                if (position == -1) size_difference = size - previous_size;
            }

            if (position == -1) position = 0;

            var removed = size_difference < 0? -size_difference: 0;
            var added = size_difference > 0? size_difference: 0;
            
            assert(position > -1);
            assert(modified > -1);
            assert(position+modified <= previous_size+removed);

            //Adding Rows at required indices if any
            for (int i = 0; i < added; i++) {
                var list_box_row = trashed_list_box_rows.is_empty? create_list_box_row(): trashed_list_box_rows.remove_at(0);
                active_list_box_rows.insert(position+i, list_box_row);
                on_bind(i, list_box_row);
            }

            //Removing Rows at required indices if any
            for (int i = 0; i < removed; i++) {
                on_unbind(active_list_box_rows[position]);
                trashed_list_box_rows.add(active_list_box_rows.remove_at(position));
            }
            
            //Notifiying the listener about the change in size of data
            if (size_difference != 0) items_changed(position, removed, added);
            
            //Modifying data if any
            for (int i = position+added; i < position+modified+added; i++) {
                on_unbind(active_list_box_rows[i]);
                on_bind (i, active_list_box_rows[i]);
            }

            previous_size = size;
        }

        public int index_of_row(ListBoxRow row) { return active_list_box_rows.index_of(row); }

        public GLib.Object? get_item (uint position) { return active_list_box_rows[(int) position]; }

        public GLib.Type get_item_type () { return typeof(ListBoxRow); }

        public abstract uint get_n_items();
    }
}