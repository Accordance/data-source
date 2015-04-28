namespace :orientdb do
  require 'orientdb4r'

  desc "Create DB"
  task :create, :host_port do |_, args|
    orientdb_host, orientdb_port = get_orientdb_connection(args[:host_port])

    client = Orientdb4r.client :host => orientdb_host, :port => orientdb_port, :ssl => false

    if ! client.database_exists? :database => DB, :user => DB_USERNAME, :password => DB_PASSWORD
      puts 'Creating DB'
      client.create_database :database => DB, :storage => :plocal, :user => DB_USERNAME, :password => DB_PASSWORD, :type => :graph
    end
  end

  desc "Drop DB"
  task :drop, :host_port do |_, args|
    orientdb_host, orientdb_port = get_orientdb_connection(args[:host_port])

    client = Orientdb4r.client :host => orientdb_host, :port => orientdb_port, :ssl => false

    if client.database_exists? :database => DB, :user => DB_USERNAME, :password => DB_PASSWORD
      puts 'Dropping DB'

      client.delete_database :database => DB, :user => DB_USERNAME, :password => DB_PASSWORD
    end
  end

  def get_orientdb_connection(orientdb_host)
    return 'localhost', 2480 unless orientdb_host

    if orientdb_host.include? ':'
      parts = orientdb_host.split(':')
      return parts[0], parts[1]
    end

    return orientdb_host, 2480
  end

  def get_db_client(host_port)
    orientdb_host, orientdb_port = get_orientdb_connection(host_port)

    client = Orientdb4r.client :host => orientdb_host, :port => orientdb_port, :ssl => false
    client.connect :database => DB, :user => DB_USERNAME, :password => DB_PASSWORD
    return client
  end

  APP_CLASS = 'Application'
  USES_CLASS = 'Uses'

  desc "Create schema"
  task :create_schema, :host_port do |_, args|
    client =  get_db_client(args[:host_port])

    client.drop_class APP_CLASS if client.class_exists? APP_CLASS
    client.drop_class USES_CLASS if client.class_exists? USES_CLASS

    client.create_class(APP_CLASS, :extends => 'V') do |c|
      c.property 'id', :string, :notnull => true, :mandatory => true
      c.property 'name', :string, :notnull => true, :mandatory => true
    end

    client.create_class(USES_CLASS, :extends => 'E') do |c|
    end

    client.command "CREATE PROPERTY Uses.out LINK Application"
    client.command "CREATE PROPERTY Uses.in LINK Application"
    client.command "ALTER PROPERTY Uses.out MANDATORY=true"
    client.command "ALTER PROPERTY Uses.in MANDATORY=true"
    client.command "CREATE INDEX UniqueUses on Uses(out,in) UNIQUE"
    client.command "CREATE INDEX UniqueApps ON Application (id, name) UNIQUE"

    client.disconnect
  end
end
