require 'json'

def load_json(file_name)
  begin
    JSON.load(File.read(file_name))
  rescue Exception => _
    puts "Failed JSON lint of #{file_name}"
    raise
  end
end

def parse_host_connection(orientdb_host, default_host, default_port)
  return default_host, default_port unless orientdb_host

  if orientdb_host.include? ':'
    parts = orientdb_host.split(':')
    return parts[0], parts[1]
  end

  return orientdb_host, default_port
end
