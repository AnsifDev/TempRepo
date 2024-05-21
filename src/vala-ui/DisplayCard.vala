using Gtk, Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/display_card.ui")]
    public class DisplayCard: Adw.Bin {
        private string? _icon_name;

        public string label { get; set; }
        public string? icon_name { 
            get { return _icon_name; } 
            set { _icon_name = value; icon.visible = icon_name != null; }
        }
        public new bool focusable {
            get { return base.focusable; }
            set { 
                base.focusable = value; 
                if (value) add_css_class ("activatable"); 
                else remove_css_class ("activatable"); 
            }
        }

        [GtkChild]
        private unowned Image icon;

        construct {
            set_activate_signal_from_name ("clicked");

            var gesture_click = new GestureClick ();
            gesture_click.released.connect (() => clicked());
            add_controller (gesture_click);

            icon.visible = icon_name != null;
            if (focusable) add_css_class ("activatable");
        }
        
        public signal void clicked();
    }
}