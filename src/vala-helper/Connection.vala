using Gee;

namespace Gitlink.Connection {
    public enum ConnectionResponse {
        OK,
        PORT_UNAVAILABLE,
        LISTENING_FAILED
    }

    public sealed class Client: Object {
        private Socket conn;
        private Cancellable service_canceller = new Cancellable ();
    
        public InetSocketAddress inet_addr { get; private set; }
    
        internal Client(Socket conn) {
            this.conn = conn;
            inet_addr = (InetSocketAddress) conn.remote_address;
    
            new Thread<void> (null, () => {
                try { listener(); } catch (Error e) {}
                disconnected ();
            });
        }
    
        //  construct { inet_addr = (InetSocketAddress) conn.remote_address; }
    
        public void end_connection() { send_message("END"); conn.close(); }
        
        private void listener() throws Error {
            while (true) {
                var string_builder = new StringBuilder();
                while (true) {
                    uint8 buffer[100];
                    ssize_t len = conn.receive (buffer, service_canceller);
                    buffer[len] = '\0';
                    if (len == 0) return;
                    
                    string_builder.append ((string) buffer);
                    //  read_buffer = read_buffer + (string) buffer;
                    if (string_builder.str.has_suffix ("\n\n")) break;
                }
    
                var contents = string_builder.str.strip ().split ("\n", 2);
                on_message_received (contents[0], contents.length > 1? contents[1]: null);
            }
        }
    
        public bool send_message(string action, string? payload = null) throws Error {
            var string_builder = new StringBuilder(@"$action\n");
            if (payload != null) string_builder.append(@"$payload\n");
            var len = conn.send(@"$(string_builder.str)\n".data);
            if (len == 0) return false;
            return true;
        }
    
        public signal void disconnected();
    
        public signal void on_message_received(string action, string? payload) { if (action == "END") conn.close(); }
    
        public static async Client? connect_to_server(string ip, int port) throws Error {
            InetAddress address = new InetAddress.from_string (ip);
            InetSocketAddress inetaddress = new InetSocketAddress (address, (uint16) port);
        
            Socket socket = new Socket (SocketFamily.IPV4, SocketType.STREAM, SocketProtocol.TCP);
            assert (socket != null);

            var t = new Thread<bool>(null, () => {
                try { socket.connect (inetaddress); } 
                catch (Error e) { Idle.add(connect_to_server.callback); return false; }
                Idle.add(connect_to_server.callback);
                return true;
            }); yield;
        
            if (!t.join()) return null;
        
            return new Client(socket);
        }
    }
    
    public class Server: Object {
        private Cancellable service_canceller = new Cancellable ();
        private Socket? socket = null;
    
        public int start(int port) throws Error {
            InetAddress address = new InetAddress.from_string ("0.0.0.0");
            InetSocketAddress inetaddress = new InetSocketAddress (address, (uint16) port);
    
            socket = new Socket (SocketFamily.IPV4, SocketType.STREAM, SocketProtocol.TCP);
            assert (socket != null);
        
            if (!socket.bind (inetaddress, true)) return ConnectionResponse.PORT_UNAVAILABLE;
            socket.listen_backlog = 5;
            if (!socket.listen ()) return ConnectionResponse.LISTENING_FAILED;
            
            service_canceller.reset();
            new Thread<void> ("Connection-Receiver", () => connection_listener (socket));
    
            return ConnectionResponse.OK;
        }
    
        public void stop() throws Error {
            service_canceller.cancel();
            if (socket != null) socket.close ();
            socket = null;
        }
    
        private void connection_listener(Socket socket) {
            try {
                while (true) {
                    var conn = socket.accept (service_canceller);
                    var client = new Client(conn);
                    client.disconnected.connect((src) => disconnected(src));
                    client.on_message_received.connect((src, action, payload) => on_message_received(src, action, payload));
                    connected(client);
                }
            } catch (Error e) {}
        }
    
        //  private void conn_handler(Socket conn) throws Error {
        //      while (true) {
        //          var string_builder = new StringBuilder();
        //          while (true) {
        //              uint8 buffer[100];
        //              ssize_t len = conn.receive (buffer, service_canceller);
        //              buffer[len] = '\0';
        //              if (len == 0) return;
                    
        //              string_builder.append ((string) buffer);
        //              //  read_buffer = read_buffer + (string) buffer;
        //              if (string_builder.str.has_suffix ("\n\n")) break;
        //          }
    
        //          var contents = string_builder.str.strip ().split ("\n", 2);
        //          onMessageReceived ((InetSocketAddress) conn.remote_address, contents[0], contents.length > 1? contents[1]: null);
    
        //          //  conn.send ("OK\n\n".data);
        //      }
        //  }
    
        public string[] get_ipv4() {
            Linux.Network.IfAddrs ifa;
            Linux.Network.getifaddrs (out ifa);
            Gee.ArrayList<string> ipv4 = new Gee.ArrayList<string>();
    
            for (unowned Linux.Network.IfAddrs temp = ifa; temp != null; temp = temp.ifa_next) {
                var a = (Posix.SockAddrIn*) temp.ifa_addr;
                if (a->sin_family != Posix.AF_INET) continue;
                InetAddress addr = new InetAddress.from_bytes ((uint8[]) a->sin_addr, Posix.AF_INET);
                ipv4.add (@"$(temp.ifa_name): $addr");
            }
    
            return ipv4.to_array ();
        }
    
        public virtual signal void connected(Client client);
    
        public virtual signal void disconnected(Client client);

        public signal void on_message_received(Client client, string action, string? payload);
    }
}