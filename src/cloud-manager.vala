/*
 * PushTheButton - Nowoczesny Cloud Manager
 * Pełna integracja z NextCloud, Google Drive, Dropbox
 */

using GLib;
using Soup;
using Json;
using Secret;

public class CloudManager : GLib.Object {
    
    public enum CloudProvider {
        NEXTCLOUD,
        GDRIVE, 
        DROPBOX
    }
    
    private Soup.Session session;
    private Logger logger;
    private Secret.Service secret_service;
    
    public CloudManager() {
        session = new Soup.Session();
        logger = new Logger();
        init_secret_service.begin();
    }
    
    private async void init_secret_service() {
        try {
            secret_service = yield Secret.Service.get(Secret.ServiceFlags.NONE);
        } catch (Error e) {
            logger.error("Failed to initialize secret service: " + e.message);
        }
    }
    
    /**
     * NextCloud WebDAV Upload
     */
    public async bool upload_to_nextcloud(string local_path, string remote_path, 
                                         string server_url, string username, string password) {
        try {
            var file = File.new_for_path(local_path);
            var file_stream = yield file.read_async();
            var file_info = yield file.query_info_async("standard::size", FileQueryInfoFlags.NONE);
            var file_size = file_info.get_size();
            
            var webdav_url = server_url + "/remote.php/dav/files/" + username + "/" + remote_path;
            var message = new Soup.Message("PUT", webdav_url);
            
            // Basic Auth
            var auth_string = username + ":" + password;
            var auth_encoded = Base64.encode(auth_string.data);
            message.request_headers.append("Authorization", "Basic " + auth_encoded);
            message.request_headers.append("Content-Type", "application/octet-stream");
            message.request_headers.set_content_length(file_size);
            
            // Stream upload
            var input_stream = new MemoryInputStream.from_data(yield file.load_contents_async());
            message.set_request_body_from_stream(input_stream, file_size, "application/octet-stream");
            
            var response = yield session.send_async(message);
            var status = message.status_code;
            
            if (status >= 200 && status < 300) {
                logger.info("NextCloud upload successful: " + remote_path);
                return true;
            } else {
                logger.error("NextCloud upload failed: HTTP " + status.to_string());
                return false;
            }
            
        } catch (Error e) {
            logger.error("NextCloud upload error: " + e.message);
            return false;
        }
    }
    
    /**
     * Google Drive OAuth2 Upload
     */
    public async bool upload_to_gdrive(string local_path, string filename, string access_token) {
        try {
            var file = File.new_for_path(local_path);
            var file_data = yield file.load_contents_async();
            
            // Metadata
            var metadata = new Json.Object();
            metadata.set_string_member("name", filename);
            
            var generator = new Json.Generator();
            generator.set_root(new Json.Node.alloc().init_object(metadata));
            var metadata_json = generator.to_data(null);
            
            // Multipart upload
            var multipart = new Soup.Multipart("multipart/related");
            multipart.append_form_string("metadata", metadata_json);
            multipart.append_form_file("file", filename, "application/octet-stream", file_data);
            
            var message = new Soup.Message.from_multipart("POST", 
                "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart", multipart);
            message.request_headers.append("Authorization", "Bearer " + access_token);
            
            var response = yield session.send_async(message);
            var status = message.status_code;
            
            if (status >= 200 && status < 300) {
                logger.info("Google Drive upload successful: " + filename);
                return true;
            } else {
                logger.error("Google Drive upload failed: HTTP " + status.to_string());
                return false;
            }
            
        } catch (Error e) {
            logger.error("Google Drive upload error: " + e.message);
            return false;
        }
    }
    
    /**
     * Dropbox API Upload
     */
    public async bool upload_to_dropbox(string local_path, string remote_path, string access_token) {
        try {
            var file = File.new_for_path(local_path);
            var file_data = yield file.load_contents_async();
            
            var message = new Soup.Message("POST", "https://content.dropboxapi.com/2/files/upload");
            message.request_headers.append("Authorization", "Bearer " + access_token);
            message.request_headers.append("Content-Type", "application/octet-stream");
            
            var dropbox_args = new Json.Object();
            dropbox_args.set_string_member("path", remote_path);
            dropbox_args.set_string_member("mode", "overwrite");
            
            var generator = new Json.Generator();
            generator.set_root(new Json.Node.alloc().init_object(dropbox_args));
            message.request_headers.append("Dropbox-API-Arg", generator.to_data(null));
            
            message.set_request_body("application/octet-stream", file_data);
            
            var response = yield session.send_async(message);
            var status = message.status_code;
            
            if (status >= 200 && status < 300) {
                logger.info("Dropbox upload successful: " + remote_path);
                return true;
            } else {
                logger.error("Dropbox upload failed: HTTP " + status.to_string());
                return false;
            }
            
        } catch (Error e) {
            logger.error("Dropbox upload error: " + e.message);
            return false;
        }
    }
    
    /**
     * Universal backup upload with progress
     */
    public async bool upload_backup(string local_path, CloudProvider provider, 
                                   owned ProgressCallback? progress_callback = null) {
        try {
            var credentials = yield get_stored_credentials(provider);
            if (credentials == null) {
                logger.error("No credentials found for provider: " + provider.to_string());
                return false;
            }
            
            var filename = Path.get_basename(local_path);
            
            switch (provider) {
                case CloudProvider.NEXTCLOUD:
                    return yield upload_to_nextcloud(local_path, filename, 
                        credentials.get_string_member("server"),
                        credentials.get_string_member("username"),
                        credentials.get_string_member("password"));
                        
                case CloudProvider.GDRIVE:
                    return yield upload_to_gdrive(local_path, filename,
                        credentials.get_string_member("access_token"));
                        
                case CloudProvider.DROPBOX:
                    return yield upload_to_dropbox(local_path, "/" + filename,
                        credentials.get_string_member("access_token"));
                        
                default:
                    logger.error("Unsupported cloud provider");
                    return false;
            }
            
        } catch (Error e) {
            logger.error("Upload backup error: " + e.message);
            return false;
        }
    }
    
    /**
     * Store credentials securely
     */
    public async bool store_credentials(CloudProvider provider, Json.Object credentials) {
        try {
            var schema = new Secret.Schema("org.pushthebutton.credentials", Secret.SchemaFlags.NONE,
                "provider", Secret.SchemaAttributeType.STRING);
                
            var attributes = new HashTable<string, string>(str_hash, str_equal);
            attributes.insert("provider", provider.to_string());
            
            var generator = new Json.Generator();
            generator.set_root(new Json.Node.alloc().init_object(credentials));
            var credentials_json = generator.to_data(null);
            
            yield Secret.password_store(schema, attributes, Secret.COLLECTION_DEFAULT,
                "PushTheButton " + provider.to_string() + " credentials", credentials_json);
                
            return true;
        } catch (Error e) {
            logger.error("Failed to store credentials: " + e.message);
            return false;
        }
    }
    
    /**
     * Retrieve stored credentials
     */
    private async Json.Object? get_stored_credentials(CloudProvider provider) {
        try {
            var schema = new Secret.Schema("org.pushthebutton.credentials", Secret.SchemaFlags.NONE,
                "provider", Secret.SchemaAttributeType.STRING);
                
            var attributes = new HashTable<string, string>(str_hash, str_equal);
            attributes.insert("provider", provider.to_string());
            
            var password = yield Secret.password_lookup(schema, attributes);
            if (password == null) return null;
            
            var parser = new Json.Parser();
            parser.load_from_data(password);
            var root = parser.get_root();
            
            if (root != null && root.get_node_type() == Json.NodeType.OBJECT) {
                return root.get_object();
            }
            
            return null;
        } catch (Error e) {
            logger.error("Failed to retrieve credentials: " + e.message);
            return null;
        }
    }
}

public delegate void ProgressCallback(int64 bytes_transferred, int64 total_bytes);