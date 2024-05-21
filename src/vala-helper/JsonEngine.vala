using Gee;

namespace Gitlink {
    public class JsonEngine: Object {
        //From Json to Hashmap/ArrayList
        public HashMap<string, Value?>? parse_string_to_hashmap(string data) throws Error {
            var parser = new Json.Parser();
            parser.load_from_data(data);
            return parse_to_hashmap(parser.get_root());
        }

        public ArrayList<Value?>? parse_string_to_array(string data) throws Error {
            var parser = new Json.Parser();
            parser.load_from_data(data);
            return parse_to_array(parser.get_root());

        }

        public HashMap<string, Value?>? parse_file_to_hashmap(string filename) throws Error {
            var parser = new Json.Parser();
            parser.load_from_file(filename);
            return parse_to_hashmap(parser.get_root());
        }

        public ArrayList<Value?>? parse_file_to_array(string filename) throws Error {
            var parser = new Json.Parser();
            parser.load_from_file(filename);
            return parse_to_array(parser.get_root());
        }

        private HashMap<string, Value?>? parse_to_hashmap(Json.Node root_node) throws Error {
            HashMap<string, Value?> hashmap = null;
            if (root_node.get_value_type().name() == typeof(Json.Object).name()) 
                hashmap = handle_json_object(root_node.get_object());
            return hashmap;
        }

        private ArrayList<Value?>? parse_to_array(Json.Node root_node) throws Error {
            ArrayList<Value?> array = null;
            if (root_node.get_value_type().name() == typeof(Json.Array).name()) 
                array = handle_json_array(root_node.get_array());
            return array;
        }

        private HashMap<string, Value?> handle_json_object(Json.Object object) {
            var hashmap = new HashMap<string, Value?>();
            foreach (var member in object.get_members()) 
                hashmap[member] = handle_json_value(object.get_member(member));
            
            return hashmap;
        }
    
        private ArrayList<Value?> handle_json_array(Json.Array array) {
            var array_list = new ArrayList<Value?>();
            foreach (var element in array.get_elements()) 
                array_list.add(handle_json_value(element)); 
            return array_list;
        }
    
        private Value? handle_json_value(Json.Node node) {
            if (node.get_value_type().name() == typeof(string).name())
                return node.get_string();
            else if (node.get_value_type().name() == typeof(int64).name())
                return (int64) node.get_int();
            else if (node.get_value_type().name() == typeof(double).name())
                return node.get_double();
            else if (node.get_value_type().name() == typeof(bool).name())
                return node.get_boolean();
            else if (node.get_value_type().name() == Type.INVALID.name())
                return null;
            else if (node.get_value_type().name() == typeof(Json.Object).name()) 
                return handle_json_object(node.get_object());
            else if (node.get_value_type().name() == typeof(Json.Array).name())
                return handle_json_array(node.get_array());
            warning("Object Extenion Not Implemented [type: %s]\n", node.get_value_type().name());
            return null;
        }

        //From Hashmap/ArrayList to Json
        public string? parse_hashmap_to_string(HashMap<string, Value?> hashmap) throws Error {
            var generator = new Json.Generator();
            var root_node = parse_hashmap(hashmap);
            generator.set_root(root_node);
            return generator.to_data(null);
        }

        public string? parse_array_to_string(ArrayList<Value?> array) throws Error {
            var generator = new Json.Generator();
            var root_node = parse_array(array);
            generator.set_root(root_node);
            return generator.to_data(null);

        }

        public void parse_hashmap_to_file(HashMap<string, Value?> hashmap, string filename) throws Error {
            var generator = new Json.Generator();
            var root_node = parse_hashmap(hashmap);
            generator.set_root(root_node);
            generator.to_file(filename);
        }

        public void parse_array_to_file(ArrayList<Value?> array, string filename) throws Error {
            var generator = new Json.Generator();
            var root_node = parse_array(array);
            generator.set_root(root_node);
            generator.to_file(filename);
        }

        private Json.Node? parse_hashmap(HashMap<string, Value?> hashmap) throws Error {
            var root_node = new Json.Node(Json.NodeType.OBJECT);
            root_node.set_object(handle_hashmap(hashmap));
            return root_node;
        }

        private Json.Node? parse_array(ArrayList<Value?> array) throws Error {
            var root_node = new Json.Node(Json.NodeType.ARRAY);
            root_node.set_array(handle_array(array));
            return root_node;
        }

        private Json.Object? handle_hashmap(HashMap<string, Value?> hashmap) {
            var json_object = new Json.Object();
            foreach (var key in hashmap.keys) 
                json_object.set_member(key, handle_value(hashmap[key]));
            return json_object;
        }
    
        private Json.Array? handle_array(ArrayList<Value?> array) {
            var json_array = new Json.Array();
            foreach (var value in array) 
                json_array.add_element(handle_value(value));
            return json_array;
        }
    
        private Json.Node? handle_value(Value? value) {
            Json.Node node;
            if (value == null) node = new Json.Node(Json.NodeType.NULL);
            else if (value.type() == typeof(HashMap)) {
                node = new Json.Node(Json.NodeType.OBJECT);
                node.set_object(handle_hashmap((HashMap<string, Value?>) value));
            } else if (value.type() == typeof(ArrayList)) {
                node = new Json.Node(Json.NodeType.ARRAY);
                node.set_array(handle_array((ArrayList<Value?>) value));
            } else {
                node = new Json.Node(Json.NodeType.VALUE);
                if (value.type() == typeof(string))
                    node.set_string((string) value);
                else if (value.type() == typeof(long))
                    node.set_int((int64) (long) value);
                else if (value.type() == typeof(int64))
                    node.set_int((int64) value);
                else if (value.type() == typeof(int))
                    node.set_int((int64) (int) value);
                else if (value.type() == typeof(double))
                    node.set_double((double) value);
                else if (value.type() == typeof(bool))
                    node.set_boolean((bool) value);
                else {
                    warning("Object Extenion Not Implemented [type: %s]\n", value.type().name());
                    return null;
                }
            }
            return node;
        }
    }
}