using Gee, Gitlink;

namespace Git {
    public class Repository: Object {
        public int64 id { get; private set; }
        public string name { get; private set; }
        public string full_name { get; private set; }
        public string url { get; private set; }
        public string? local_url { get; private set; }
        public string ssh_url { get; private set; }
        public bool private_repo { get; private set; }
        public string owner { get; private set; }
        public string? description { get; private set; }
        public int64 forks { get; private set; }

        internal Repository(HashMap<string, Value?> data_map) {
            id = (int64) data_map["id"];
            update_from_HashMap(data_map);
        }

        public void update_from_HashMap(HashMap<string, Value?> data_map) {
            name = data_map["name"] as string;
            full_name = data_map["full_name"] as string;
            url = data_map["html_url"] as string;
            if (data_map.has_key("local_url")) local_url = data_map["local_url"] as string;
            ssh_url = data_map["ssh_url"] as string;
            private_repo = (bool) data_map["private"];
            owner = ((HashMap<string, Value?>) data_map["owner"])["login"] as string;
            if (data_map.has_key("description") && data_map["description"] != null) 
                description = data_map["description"] as string;
            forks = (int64) data_map["forks"];
        }

        public async bool update() {
            try {
                var client = Client.get_default();
                var user = yield client.load_user(owner);
                var response = yield request(@"repos/$full_name", user);
                if (response == null) return false;

                var data_map = new JsonEngine().parse_string_to_hashmap(response);
                update_from_HashMap(data_map);
            } catch (Error e) { printerr(@"ERR: $(e.message)\n"); }

            return false;
        }

        public HashMap<string, Value?> to_hashmap() {
            var owner_map = new HashMap<string, Value?>();
            owner_map["login"] = owner;
            
            var data = new HashMap<string, Value?>();
            data["id"] = id;
            data["name"] = name;
            data["full_name"] = full_name;
            data["html_url"] = url;
            if (local_url != null) data["local_url"] = local_url;
            data["ssh_url"] = ssh_url;
            data["private"] = private_repo;
            data["forks"] = forks;
            data["owner"] = owner_map;
            if (description != null) data["description"] = description;

            return data;
        }
    }
}