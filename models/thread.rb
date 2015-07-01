module Model
  class Thread
    attr_reader :db, :table

    def initialize
      @table = Thread.table
      @db = Connector.db
    end

    def self.table
      "Threads"
    end

    def create(params)
      user_id = User.get_id(db, params['user'])
      forum_id = Forum.find_by_short_name(db, params['forum'])['id']
      db.query(
        "INSERT INTO #{table} SET
          user_id = '#{user_id}',
          forum_id = '#{forum_id}',
          title = '#{params['title']}',
          slug = '#{params['slug']}',
          isDeleted = #{params['isDeleted']},
          isClosed = #{params['isClosed']},
          date = '#{params['date']}',
          message = '#{params['message']}';"
      )
      result = Thread.find_by_id(db, db.last_id)
      Response.new(code: :ok, body: result).take
    end

    def details(params)
      result = Thread.find_by_id(db, params['thread'], params['related'])
      Response.new(code: :ok, body: result).take
    end

    def subscribe(params)
      user_id = User.get_id(db, params['user'])
      db.query(
        "INSERT IGNORE INTO Subscriptions SET
          user_id = #{user_id},
          thread_id = #{params['thread']};"
      )
      result = params
      Response.new(code: :ok, body: result).take
    end

    def unsubscribe(params)
      user_id = User.get_id(db, params['user'])
      db.query(
        "DELETE FROM Subscriptions
         WHERE user_id = #{user_id}
         AND thread_id = #{params['thread']};"
      )
      result = params
      Response.new(code: :ok, body: result).take
    end

    def self.find_by_id(db, id, related = [])
      related ||= []
      res = db.query(
        "SELECT * FROM #{table}
         WHERE id = '#{id}';"
      ).first
      raise RuntimeError if res.nil?
      res['date'] = res['date'].strftime('%Y-%m-%d %H:%M:%S')

      if related.include? 'user'
        res['user'] = User.find_by_id(db, res['user_id'])
      else
        res['user'] = User.find_by_id(db, res['user_id'])['email']
      end

      if related.include? 'forum'
        res['forum'] = Forum.find_by_id(db, res['forum_id'])
      else
        res['forum'] = Forum.find_by_id(db, res['forum_id'])['short_name']
      end
      res
    rescue RuntimeError => e
      Response.new(code: :not_found, body: e.message).take
    end
  end
end
