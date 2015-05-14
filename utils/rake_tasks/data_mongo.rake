namespace :mongo do
  require 'mongo'
  require_relative 'utils'

  desc 'Create DB'
  task :create, [:host_port] => :drop do |_, args|
    mongodb_host, mongodb_port = parse_host_connection(args[:host_port], "localhost", 27017)
    client = Mongo::Client.new([ "#{mongodb_host}:#{mongodb_port}" ], :database => 'catalog')

    json = load_json('data/change_events.json')
    start_time = Time.now
    json.each do |item|
      item['created_at'] = item['time'] = start_time
      start_time -= 43000
    end
    result = client[:change_events].insert_many(json)

    json = load_json('data/maintenance_events.json')
    start_time = Time.now
    json.each do |item|
      item['created_at'] = start_time
      time_start = Time.parse(item['time_frame']['start'])
      time_end = Time.parse(item['time_frame']['end'])
      lenght = time_end - time_start
      item['time_frame']['end'] = start_time.utc.iso8601
      item['time_frame']['start'] = (start_time - lenght).utc.iso8601
      start_time -= 43000
    end
    result = client[:maintenance_events].insert_many(json)
  end

  desc 'Clear DB'
  task :drop, :host_port do |_, args|
    mongodb_host, mongodb_port = parse_host_connection(args[:host_port], "localhost", 27017)
    client = Mongo::Client.new([ "#{mongodb_host}:#{mongodb_port}" ], :database => 'catalog')
    change_events = client[:change_events]
    change_events.drop
    maintenance_events = client[:maintenance_events]
    maintenance_events.drop
  end
end
