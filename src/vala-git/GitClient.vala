using Gtk, Gee, Soup, Gitlink;

namespace Git {
    public class Client: Object {
        private static Client? instance;

        public static Client get_default() {
            if (instance == null) instance = new Client();
            return instance;
        }

        private HashMap<int, User> user_store = new HashMap<int, User>();
        private HashMap<int, Repository> repo_store = new HashMap<int, Repository>();

        private ArrayList<Value?> local_users;
        //  public User? active_user { get; set; default = null; }

        private Client() {
            print("Booting Git Client...\n");
            var config_path = @"$(Environment.get_user_config_dir())/git_client.config";
            if (File.new_for_path(config_path).query_exists()) {
                print("\t* Loading Configuration...\n");

                HashMap<string, Value?> config_map = null;
                try { config_map = new JsonEngine().parse_file_to_hashmap(config_path); }
                catch (Error e) { print(@"ERR: $(e.message)\n"); }

                if (config_map != null) {
                    if (config_map.has_key("users")) local_users = config_map["users"] as ArrayList<Value?>;
                }
            } else print("\t* Configurations are set to defaults\n");

            if (local_users == null) local_users = new ArrayList<Value?>();

            GLib.Application.get_default().shutdown.connect(save);
            print("Booting Git Client\t\t[OK]\n");
        }

        private void save() {
            print("Shuting down Git Client\n");
            var config_path = @"$(Environment.get_user_config_dir())/git_client.config";
            var config_map = new HashMap<string, Value?>();
            var json_engine = new JsonEngine();

            print("\t* Saving Configuration...\n");
            config_map["users"] = local_users;
            try { json_engine.parse_hashmap_to_file(config_map, config_path); }
            catch (Error e) { print(@"ERR: $(e.message)\n"); }
            
            foreach (var uid_value in local_users) try {
                var uid = uid_value.get_int64();

                if (!user_store.has_key((int) uid)) continue;
                var cached_user = user_store[(int) uid];

                //Cache check
                var user_data_map = cached_user.to_hashmap();
                var user_data_path = @"$(Environment.get_user_data_dir())/$(cached_user.id)";

                print(@"\t* Saving Data of User: $(cached_user.name)...\n");
                json_engine.parse_hashmap_to_file(user_data_map, user_data_path);

                print(@"\t* Saving Configurations of User: $(cached_user.name)...\n");
                cached_user.save_configurations();

                print(@"\t* Saving Repository Data of User: $(cached_user.name)...\n");
                foreach (var rid_value in cached_user.remote_repos) {
                    var rid = rid_value.get_int64();

                    if (!repo_store.has_key((int) rid)) continue;
                    var cached_repo = repo_store[(int) rid];
    
                    var repo_data_map = cached_repo.to_hashmap();
                    var repo_data_path = @"$(Environment.get_user_data_dir())/$(cached_repo.id)";

                    print(@"\t\t* Saving Data of Repository: $(cached_repo.name)...\n");
                    json_engine.parse_hashmap_to_file(repo_data_map, repo_data_path);
                }
            } catch (Error e) { print(@"ERR: $(e.message)\n"); }

            print("Shuting down Git Client\t\t[OK]\n");
        }

        public async ArrayList<Repository>? load_repositories(User user, bool offline = false) throws Error {
            var repos = new ArrayList<Repository>();
            var json_engine = new JsonEngine();

            if (offline) foreach (var id_value in user.remote_repos) {
                var rid = (int64) id_value;
                var file_path = @"$(Environment.get_user_data_dir())/$rid";
                
                if (!repo_store.has_key((int) rid)) {
                    var repo_data_map = json_engine.parse_file_to_hashmap(file_path);
                    repo_store[(int) rid] = new Repository(repo_data_map);
                }

                repos.add(repo_store[(int) rid]);
            } else {
                // Fetching Fresh Data
                var response_str = yield request(@"user/repos", user);
                if (response_str == null) return null;

                var repo_data_array = json_engine.parse_string_to_array(response_str);
                user.remote_repos.clear();

                // Parsing Data
                foreach (var repo_data_map_value in repo_data_array) {
                    var repo_data_map = repo_data_map_value as HashMap<string, Value?>;
                    var rid = (int64) repo_data_map["id"];
                    user.remote_repos.add(rid);

                    // Cache Check
                    if (repo_store.has_key((int) rid)) repo_store[(int) rid].update_from_HashMap(repo_data_map);
                    else repo_store[(int) rid] = new Repository(repo_data_map);

                    //  print(@"Cached $rid, $(repo_store[(int) rid] != null)\n");
                    repos.add(repo_store[(int) rid]);
                }
            }
            

            //  try {
            //      var response = yield request(@"user/repos", user);
            //      if (response == null) return null;

            //      var json_engine = new JsonEngine();
            //      var data_array = json_engine.parse_string_to_array(response);
                

            //      foreach (var data_map_value in data_array) {
            //          var data_map = data_map_value as HashMap<string, Value?>;
            //          var rid = (int64) data_map["id"];
            //          Repository? repo = null;
                    
            //          foreach (var cached_repo in repo_store) if (cached_repo.id == rid) {
            //              repo = cached_repo;
            //              break;
            //          }

            //          if (repo == null) repo_store.add(repo = new Repository(data_map));
            //          else repo.update_from_HashMap(data_map);

            //          repos.add(repo);
            //      }

            //      return repos;
            //  } catch (Error e) { printerr(@"ERR: $(e.message)\n"); }

            return repos;
        }

        public ArrayList<Repository> load_local_repositories(User user) {
            var repos = new ArrayList<Repository>();
            var invalid_repos = new ArrayList<Value?>();

            if (user.local_repos != null) foreach (var rid_value in user.local_repos) {
                var rid = rid_value.get_int64();

                //Cache check
                if (repo_store.has_key((int) rid)) repos.add(repo_store[(int) rid]);
                else {
                    //Fallback Fetch
                    var file_path = @"$(Environment.get_user_data_dir())/$rid";
                    if (File.new_for_path(file_path).query_exists()) try {
                        var json_engine = new JsonEngine();
                        var data_map = json_engine.parse_file_to_hashmap(file_path);
                        
                        repo_store[(int) rid] = new Repository(data_map);
                        repo_store[(int) rid].update.begin();
                        repos.add(repo_store[(int) rid]);
                    } catch (Error e) { invalid_repos.add(rid_value); }
                    else invalid_repos.add(rid_value);
                }
            }

            foreach (var rid in invalid_repos) user.local_repos.remove((int) rid);

            return repos;
        }

        public async Repository? load_repository(string full_name, User user) throws Error {
            //Cache check
            foreach (var rid in repo_store.keys) 
                if (repo_store[(int) rid].full_name == full_name) return repo_store[(int) rid];

            //Fallback Fetch
            var response = yield request(@"repos/$full_name", user);
            if (response == null) return null;

            var json_engine = new JsonEngine();
            var data_map = json_engine.parse_string_to_hashmap(response);
            var repo = new Repository(data_map);
            
            repo_store[(int) repo.id] = repo;
            return repo;
        }

        public ArrayList<User> load_local_users() {
            var users = new ArrayList<User>();
            var invalid_users = new ArrayList<Value?>();

            foreach (var uid_value in local_users) {
                var uid = uid_value.get_int64();

                //Cache check
                if (user_store.has_key((int) uid)) users.add(user_store[(int) uid]);
                else {
                    var file_path = @"$(Environment.get_user_data_dir())/$uid";
                    if (File.new_for_path(file_path).query_exists()) try {
                        var json_engine = new JsonEngine();
                        var data_map = json_engine.parse_file_to_hashmap(file_path);
                        
                        user_store[(int) uid] = new User(data_map);
                        user_store[(int) uid].update.begin();
                        users.add(user_store[(int) uid]);
                    } catch (Error e) { invalid_users.add(uid_value); }
                    else invalid_users.add(uid_value);
                }
            }

            foreach (var uid in invalid_users) local_users.remove((int) uid);

            return users;
        }

        public async User? load_user(string username) throws Error {
            // Cache Check
            foreach (var uid in user_store.keys) 
                if (user_store[(int) uid].username == username) return user_store[(int) uid];

            //Fallback Fetch
            var response = yield request(@"users/$username", null);
            if (response == null) return null;

            var json_engine = new JsonEngine();
            var data_map = json_engine.parse_string_to_hashmap(response);
            var user = new User(data_map); 
            
            user_store[(int) user.id] = user;
            return user;
        }

        public void set_as_local_user(User user) {
            foreach (var element in local_users) if (element.get_int64() == user.id) return;
            local_users.add(user.id);
        }

        public async User authenticate (string device_code, int expire, int interval) throws Error {
            print(@"Processing Request authenticate\n");
            HashMap<string, Value?> response_map = null;

            for (int i = 0; i < expire/(interval*2); i++) {
                print("\t* Polling for Authorization: ");
                var url = @"https://github.com/login/oauth/access_token?client_id=fe459acb22155ceef1f6&device_code=$device_code&grant_type=urn:ietf:params:oauth:grant-type:device_code";

                var msg = new Soup.Message("POST", url);
                msg.request_headers.append("Accept", "application/vnd.github+json");
                msg.request_headers.append("User-Agent", "HashFolder");

                var session = new Soup.Session();
                var response_bytes = yield session.send_and_read_async(msg, 0, null);
                var response = (string) response_bytes.get_data();
                response_map = new JsonEngine().parse_string_to_hashmap(response);

                if (!response_map.has_key("error")) break;
                else if (response_map["error"] != "authorization_pending") break;

                print(" [Not Authenticated]\n");
                Timeout.add_seconds(interval*2, () => { authenticate.callback(); return false; });
                yield;
            }

            if (response_map.has_key("error")) {
                print("[Cancelled or Failed]\n");
                throw new Error(GLib.Quark.from_string("ERR_REJECTED"), 1, @"$(response_map["error"].get_string())");
            };

            print(" [Authenticated]\n");
            print("\t* Fetching User Account Details\n");
            var token = (string) response_map["access_token"];
            var url = "https://api.github.com/user";

            var msg = new Soup.Message("GET", url);
            msg.request_headers.append("Accept", "application/vnd.github+json");
            msg.request_headers.append("Authorization", @"Bearer $token");
            msg.request_headers.append("User-Agent", "HashFolder");

            var session = new Soup.Session();
            var response_bytes = yield session.send_and_read_async(msg, 0, null);
            var response = (string) response_bytes.get_data();

            var user_map = new JsonEngine().parse_string_to_hashmap(response);
            var uid = (int) user_map["id"].get_int64();

            print("\t* Registering User Account\n");
            if (!user_store.has_key(uid)) user_store[uid] = new User(user_map);
            user_store[uid].token = token;
            set_as_local_user(user_store[uid]);

            print(@"Processing Request authenticate\t\t[OK]\n");
            return user_store[uid];
        }
    }
}