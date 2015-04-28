namespace :data_graph do
  require 'orientdb4r'
  require 'json'

  desc "Import data"
  task :import, :host_port do |_, args|
    json = load_json('data/applications_demo.json')
    nodes = {}
    json.each do |item|
      # id = line.downcase.tr(" ", "_").tr('-', '_').tr("'", "").tr("’", "").tr(".", "")
      nodes[item['id']] = item
    end

    connections = {}

    client =  get_db_client(args[:host_port])
    nodes.each do |id, node|
      uses = node.delete('uses') if node.key? 'uses'

      node['@class'] = 'Application'
      # puts node

      doc = client.create_document node

      info = { id: doc['@rid'], uses: uses }

      puts "#{id}: #{info[:id]}"
      connections[id] = info
    end

    connections.each do |id, info|
      puts "#{id} ** #{info}"
      uses = (info.fetch(:uses, []) || []).map do |i|
        connections.fetch(i, { id: nil })[:id]
      end
      puts uses.join(',')
      create_connections client, info[:id], uses
    end

    client.disconnect
  end

  desc "Drop Data"
  task :drop, :host_port do |_, args|
    client =  get_db_client(args[:host_port])

    client.command "DELETE VERTEX Application"
    client.command "DELETE EDGE Uses"
    client.disconnect
  end

  def load_json(file_name)
    begin
      JSON.load(File.read(file_name))
    rescue Exception => _
      puts "Failed JSON lint of #{file_name}"
      raise
    end
  end

  def create_connections(client, from_id, connections)
    connections.each do |to_id|
      # next if to_id.nil?
      q = "CREATE EDGE Uses FROM #{from_id} TO #{to_id}"
      puts q
      client.command q
    end
  end

end
