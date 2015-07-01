module Model
  class System
    attr_reader :db

    def initialize
      @db = Connector.db
    end

    def clear
      db.query("DELETE FROM forum_authors;")
      db.query("DELETE FROM subscription;")
      db.query("DELETE FROM following;")
      db.query("DELETE FROM post;")
      db.query("DELETE FROM thread;")
      db.query("DELETE FROM forum;")
      db.query("DELETE FROM user;")
      Response.new(code: :ok, body: "OK").take
    end

    def status
    end

  end
end
