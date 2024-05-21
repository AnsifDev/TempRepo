using Gee, Gitlink;

namespace Git {
    private const string id = "fe459acb22155ceef1f6";
    private const string secret = "5a76b3547bd2a952b3d881ad3aa0bf3793770595";

    public async string? request(string end_point, User? user) throws Error {
        print(@"Processing GET Request $end_point\n");
        var url = "https://"+(user == null || user.token == null? @"$id:$secret@": "")+@"api.github.com/$end_point";

        var msg = new Soup.Message("GET", url);
        msg.request_headers.append("Accept", "application/vnd.github+json");
        if (user != null && user.token != null) msg.request_headers.append("Authorization", @"Bearer $(user.token)");
        msg.request_headers.append("User-Agent", "GitLink");

        var session = new Soup.Session();
        var response_bytes = yield session.send_and_read_async(msg, 0, null);
        var response = (string) response_bytes.get_data();
        print(@"Processing GET Request $end_point\t\t[$(msg.status_code)]\n");
        return msg.status_code-200 < 100? response: null;
    }

    public async string? post_request(string end_point, HashMap<string, Value?>? body, User? user) throws Error {
        print(@"Processing POST Request $end_point\n");
        var url = "https://"+(user == null || user.token == null? @"$id:$secret@": "")+@"api.github.com/$end_point";
        var body_str = """{"key":"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA9vwWOhLAhvG5JnVmCJYTc7MUOTCbrS8s548qu66Ewg","title":"TestKeyGitLink"}""";

        var msg = new Soup.Message("POST", url);
        msg.request_headers.append("Accept", "application/vnd.github+json");
        msg.request_headers.append("Content-Type", "application/vnd.github+json");
        if (user != null && user.token != null) msg.request_headers.append("Authorization", @"Bearer $(user.token)");
        msg.request_headers.append("User-Agent", "GitLink");
        
        if (body != null) {
            var msg_body = new Soup.MessageBody();
            msg_body.append_take((uint8[]) body_str.to_utf8());
            msg.set_request_body_from_bytes("application/vnd.github+json", msg_body.flatten());
        }
        //  if (body != null) msg.set_request_body_from_bytes("application/vnd.github+json", new Bytes.static( (uint8[]) body_str.to_utf8()));
        
        print("%s\n", body_str);

        var session = new Soup.Session();
        var response_bytes = yield session.send_and_read_async(msg, 0, null);
        var response = (string) response_bytes.get_data();
        print(@"Processing GET Request $end_point\t\t[$(msg.status_code)]\n");
        print("\n\n%s\n\n", response);
        return msg.status_code-200 < 100? response: null;
    }

    public async HashMap<string, Value?>? get_login_code() throws Error {
        print(@"Processing POST Request login/code\n");

        var url = "https://github.com/login/device/code?client_id=fe459acb22155ceef1f6&scope=repo%20user%20admin:public_key";

        var body = new HashMap<string, Value?>();
        body["client_id"] = "fe459acb22155ceef1f6";
        body["scopes"] = "repo user admin:public_key";

        var body_str = new JsonEngine().parse_hashmap_to_string(body);
        print(@"$body_str\n");

        var msg = new Soup.Message("POST", url);
        msg.request_headers.append("Accept", "application/vnd.github+json");
        msg.request_headers.append("User-Agent", "GitLink");

        var session = new Soup.Session();
        var response_bytes = yield session.send_and_read_async(msg, 0, null);
        var response = (string) response_bytes.get_data();
        print(@"Processing POST Request login/code\t\t[OK]\n");
        
        if (msg.status_code-200 >= 100) return null;
        return new JsonEngine().parse_string_to_hashmap(response);
    }
}