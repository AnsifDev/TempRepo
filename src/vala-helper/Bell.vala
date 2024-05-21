namespace Gitlink {
    public class Bell : Object {
        private Gtk.MediaFile media_file;
        private GLib.File file;

        public bool ringing {
            get { return media_file.playing; }
            set {
                if (value) ring();
                else stop();
            }
        }

        public bool repeatable { get; set; default = true; }
    
        public Bell (GLib.File sound) {
            if (sound == null) {
                warning ("Sound is missing");
                return;
            }
    
            file = sound;
        }
    
        private void ring() {
            media_file = Gtk.MediaFile.for_file (file);
    
            media_file.set_loop (repeatable);
            media_file.notify["prepared"].connect (() => {
                if (!media_file.has_audio) {
                    warning ("Invalid sound");
                }
            });
    
            media_file.play_now ();
        }
    
        private void stop () {
            if (media_file == null) {
                return;
            }
    
            media_file.set_playing (false);
            media_file.close ();
            media_file = null;
        }
    }
}