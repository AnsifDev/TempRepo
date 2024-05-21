using Gee, Gtk;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/repo_clone_dialog.ui")]
    public class RepoCloneDialog: Adw.Window {
        [GtkChild]
        unowned ListBox list_box;

        public RepoCloneDialog(Git.User user) {
            modal = true;
            transient_for = Application.get_default().active_window;

            var client = Git.Client.get_default();
            client.load_repositories.begin(user, true, (src, result) => {
                var repos = client.load_repositories.end(result);
                list_box.bind_model(new ReposListModel(repos), (item) => item as Widget);
            });
            //  list_box.bind_model(new ReposListModel(Git.Client.get_default().get_local_repositories(user)), (item) => item as Widget);
        }
    }
}