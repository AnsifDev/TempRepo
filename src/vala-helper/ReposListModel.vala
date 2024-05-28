using Gee, Gtk;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/repos_row.ui")]
    class ReposRow: Adw.ExpanderRow {
        public string description { get; set; }
        public string url { get; set; }
        public string git_ssh_url { get; set; }
        public bool cloned { get; set; }

        [GtkCallback]
        public void open_web() {
            new UriLauncher(url).launch.begin(Application.get_default().active_window, null);
        }
    }

    public class ReposListModel: RecycleViewModel {
        private ArrayList<Git.Repository> data;
        
        public ReposListModel(ArrayList<Git.Repository> src) { 
            data = src;
            initialize(); 
        }

        public Value? get_data_for_row(ListBoxRow row) { return data[index_of_row(row)]; }

        public int index_of_item(Git.Repository value) { return data.index_of(value); }

        public override ListBoxRow create_list_box_row() { return new ReposRow(); }

        public override void on_bind(int position, ListBoxRow list_box_row) {
            var repo = data[(int) position];
            var repos_row = list_box_row as ReposRow;
            repos_row.title = repo.name;
            repos_row.subtitle = repo.private_repo? "Private Repo": "Private Repo";
            repos_row.description = repo.description != null? repo.description: "No Description Provided";
            repos_row.url = repo.url;
            repos_row.git_ssh_url = repo.ssh_url;
            repos_row.cloned = repo.local_url != null;
        }

        public override uint get_n_items () { return data.size; }
    }
}