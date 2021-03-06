namespace :data_graph do
  require 'orientdb4r'
  require_relative 'utils'

  desc "Import data"
  task :import, [ :host_port ] => [ :import_apps, :import_teams ]

  desc "Import Applications"
  task :import_apps, :host_port do |_, args|
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

      puts "#{id}: #{info[:id]}" if LOG_LEVEL == 'DEBUG'
      connections[id] = info
    end

    connections.each do |id, info|
      puts "#{id} ** #{info}"
      uses = (info.fetch(:uses, []) || []).map do |i|
        connections.fetch(i, { id: nil })[:id]
      end
      puts uses.join(',') if LOG_LEVEL == 'DEBUG'
      create_connections client, 'Uses', info[:id], uses
    end

    client.disconnect
  end

  desc "Import teams"
  task :import_teams, :host_port do |_, args|
    json = load_json('data/teams.json')

    client =  get_db_client(args[:host_port])

    json.each do |team|
      team['@class'] = 'Team'
      team_id = team['id']
      team_doc = client.create_document team
      puts "Team: #{team_id} -> #{team_doc['@rid']}" if LOG_LEVEL == 'DEBUG'

      apps = client.query("SELECT FROM Application WHERE owner = '#{team_id}'")
      app_connections = apps.map { |app| app['@rid'] }
      create_connections client, 'Owns', team_doc['@rid'], app_connections
    end

    client.disconnect
  end

  desc "Drop Data"
  task :drop, :host_port do |_, args|
    client =  get_db_client(args[:host_port])

    client.command 'DELETE VERTEX Team'
    client.command 'DELETE EDGE Owns'
    client.command 'DELETE VERTEX Application'
    client.command 'DELETE EDGE Uses'
    client.disconnect
  end


  def create_connections(client, type, from_id, connections)
    connections.each do |to_id|
      # next if to_id.nil?
      q = "CREATE EDGE #{type} FROM #{from_id} TO #{to_id}"
      puts q if LOG_LEVEL == 'DEBUG'
      client.command q
    end
  end

end
