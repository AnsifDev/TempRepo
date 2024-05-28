int main (string[] args) {
    var server = new Gitlink.Connection.Server();
    server.on_message_received.connect((client, action, payload) => {
        print("%s: %s\n", action, payload);
    });
    server.start(3000);
    
    foreach (var ip in server.get_ipv4()) print("Serving on %s:3000\n", ip);

    new MainLoop().run();
    

    return 0;
}