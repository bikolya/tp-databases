require 'singleton'

class Connector
  include Singleton
  attr_reader :db

  def initialize
    @db = Mysql2::Client.new(
      host: 'localhost',
      username: ENV['DB_USER'],
      database: ENV['DB_NAME'],
      password: ENV['DB_PASSWORD'],
      cast_booleans: true
    )
  end

  def self.db
    Connector.instance.db
  end
end
