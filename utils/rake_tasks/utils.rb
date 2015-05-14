require 'json'

def load_json(file_name)
  begin
    JSON.load(File.read(file_name))
  rescue Exception => _
    puts "Failed JSON lint of #{file_name}"
    raise
  end
end
