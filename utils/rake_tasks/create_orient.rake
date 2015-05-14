namespace :orientdb do
  require 'orientdb4r'

  desc 'Create DB'
  task :create, :host_port do |_, args|
    orientdb_host, orientdb_port = parse_host_connection(args[:host_port], "localhost", 2480)

    client = Orientdb4r.client :host => orientdb_host, :port => orientdb_port, :ssl => false

    if ! client.database_exists? :database => DB, :user => DB_USERNAME, :password => DB_PASSWORD
      puts 'Creating DB'
      client.create_database :database => DB, :storage => :plocal, :user => DB_USERNAME, :password => DB_PASSWORD, :type => :graph
    end
  end

  desc 'Drop DB'
  task :drop, :host_port do |_, args|
    orientdb_host, orientdb_port = parse_host_connection(args[:host_port], "localhost", 2480)

    client = Orientdb4r.client :host => orientdb_host, :port => orientdb_port, :ssl => false

    if client.database_exists? :database => DB, :user => DB_USERNAME, :password => DB_PASSWORD
      puts 'Dropping DB'

      client.delete_database :database => DB, :user => DB_USERNAME, :password => DB_PASSWORD
    end
  end

  def get_db_client(host_port)
    orientdb_host, orientdb_port = parse_host_connection(host_port, "localhost", 2480)

    client = Orientdb4r.client :host => orientdb_host, :port => orientdb_port, :ssl => false
    client.connect :database => DB, :user => DB_USERNAME, :password => DB_PASSWORD
    return client
  end

  APP_CLASS = 'Application'
  USES_CLASS = 'Uses'
  TEAM_CLASS = 'Team'
  OWNS_CLASS = 'Owns'

  desc 'Create schema'
  task :create_schema, :host_port do |_, args|
    client =  get_db_client(args[:host_port])

    if client.class_exists? APP_CLASS
      client.command "DELETE VERTEX #{APP_CLASS}"
      client.drop_class APP_CLASS
    end
    if client.class_exists? TEAM_CLASS
      client.command "DELETE VERTEX #{TEAM_CLASS}"
      client.drop_class TEAM_CLASS
    end
    client.drop_class USES_CLASS if client.class_exists? USES_CLASS
    client.drop_class OWNS_CLASS if client.class_exists? OWNS_CLASS

    # Creating Applications
    client.create_class(APP_CLASS, :extends => 'V') do |c|
      c.property 'id', :string, :notnull => true, :mandatory => true
      c.property 'name', :string, :notnull => true, :mandatory => true
    end

    client.create_class(USES_CLASS, :extends => 'E') do |c|
    end

    client.command "CREATE PROPERTY Uses.out LINK #{APP_CLASS}"
    client.command "CREATE PROPERTY Uses.in LINK #{APP_CLASS}"
    client.command 'ALTER PROPERTY Uses.out MANDATORY=true'
    client.command 'ALTER PROPERTY Uses.in MANDATORY=true'

    client.command 'DROP INDEX UniqueUses'
    client.command 'CREATE INDEX UniqueUses on Uses(out,in) UNIQUE'
    client.command 'DROP INDEX UniqueApps'
    client.command 'CREATE INDEX UniqueApps ON Application (id, name) UNIQUE'

    # Creating Teams
    client.create_class(TEAM_CLASS, :extends => 'V') do |c|
      c.property 'id', :string, :notnull => true, :mandatory => true
      c.property 'name', :string, :notnull => true, :mandatory => true
    end

    client.create_class(OWNS_CLASS, :extends => 'E') do |c|
    end

    client.command "CREATE PROPERTY Owns.out LINK #{TEAM_CLASS}"
    client.command "CREATE PROPERTY Owns.in LINK #{APP_CLASS}"
    client.command 'ALTER PROPERTY Owns.out MANDATORY=true'
    client.command 'ALTER PROPERTY Owns.in MANDATORY=true'

    client.command 'DROP INDEX UniqueTeams'
    client.command 'CREATE INDEX UniqueTeams ON Team (id, name) UNIQUE'


    client.disconnect
  end
end
