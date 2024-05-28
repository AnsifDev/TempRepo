using Gee;

namespace Gitlink {
    public class SSHConfiguration: HashMap<string, HostConfiguration> {
        private string filepath;
        
        private SSHConfiguration(string filepath) {
            this.filepath = filepath;
        }

        public void save() throws Error {
            var file = File.new_for_path(filepath);
        
            var config_strings = new ArrayList<string>();
            foreach (var host in keys) config_strings.add(this[host].to_string());
        
            //  if (file.query_exists()) file.delete(null);
            var data_output_stream = new DataOutputStream(file.replace(null, false, GLib.FileCreateFlags.NONE, null));
            data_output_stream.put_string(string.joinv("\n\n", config_strings.to_array()), null);
        }

        public static SSHConfiguration load(string filepath = Environment.get_home_dir()+"/.ssh/config") throws Error {
            var instance = new SSHConfiguration(filepath);
            var file = File.new_for_path(filepath);
        
            if (!file.query_exists()) return instance;
            var data_input_stream = new DataInputStream(file.read());
        
            HostConfiguration? current_config = null;
            string line;
            while((line = data_input_stream.read_line(null, null)) != null) {
                if (line.length == 0 || line.substring(0, 1) == "#") continue;
        
                var parts = line.strip().split(" ", 2);
                if (parts.length < 2) continue;
        
                var key = parts[0];
                var value = parts[1];
        
                if (key == "Host") {
                    if (current_config != null) instance[current_config.host] = current_config;
                    current_config = new HostConfiguration(value);
                } else if (current_config != null) current_config[key] = value;
            } if (current_config != null) instance[current_config.host] = current_config;

            return instance;
        }
    }

    public class HostConfiguration: HashMap<string, string> {
        public string host { get; private set; }

        public HostConfiguration(string host) { this.host = host; }

        public HostConfiguration.for_github(string host, string? identity_file = null) {
            this(host);
            this["Host"] = "github.com";
            this["User"] = "git";
            if (identity_file != null) this["IdentityFile"] = identity_file;
        }

        public string to_string() {
            var lines = new ArrayList<string>();

            lines.add(@"Host $host");
            foreach (var key in keys) lines.add(@"    $key $(this[key])");

            return string.joinv("\n", lines.to_array());
        }
    }
}