module Model
  class System
    attr_reader :db

    def initialize
      @db = Connector.db
    end

    def clear
      db.query("DELETE FROM #{User.table};")
      db.query("DELETE FROM #{Forum.table};")
      db.query("DELETE FROM #{Thread.table};")
      db.query("DELETE FROM #{Post.table};")
      db.query("DELETE FROM Followers;")
      db.query("DELETE FROM Subscriptions;")
      Response.new(code: :ok, body: "OK").take
    end

    def status
    end

  end
end
