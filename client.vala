int main (string[] args) {
    print(">> Enter the ip address: ");
    var ip = stdin.read_line();
    print(">> Enter the Device name: ");
    var dev_name = stdin.read_line();
    VolumeMonitor monitor = VolumeMonitor.get ();
    Gitlink.Connection.Client.connect_to_server.begin(ip, 3000, (src, res) => {
        var client = Gitlink.Connection.Client.connect_to_server.end(res);

        print(@"Connected to $(client.inet_addr)\n");

        client.on_message_received.connect((action, payload) => {
            print(@"[$(client.inet_addr)] $action%s", payload == null? "\n": @": $payload\n");
        });

        client.disconnected.connect(() => {
            print(@"Disconnected from $(client.inet_addr)\n");
        });

        GLib.Timeout.add(1000, () => { client.send_message("NAME", dev_name); return false; });

        monitor.mount_added.connect ((mount) => {
            print ("Mount added: %s\n", mount.get_name ());
            mount.unmount_with_operation (GLib.MountUnmountFlags.NONE, null, null);
            client.send_message("MOUNT", mount.get_name ());
        });
        
        
    });

    new MainLoop().run();


    return 0;
}
