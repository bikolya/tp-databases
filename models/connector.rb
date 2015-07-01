require 'singleton'

class Connector
  include Singleton
  attr_reader :db

  def initialize
    @db = Mysql2::Client.new(
      host: 'localhost',
      username: 'root',
      database: 'forum_db',
      password: 'qweqwe',
      cast_booleans: true
    )
  end

  def self.db
    Connector.instance.db
  end
end
