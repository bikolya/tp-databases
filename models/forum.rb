module Model
  class Forum
    include Model::Helpers
    attr_reader :db, :table

    def initialize
      @table = Forum.table
      @db = Connector.db
    end

    def self.table
      "Forums"
    end

    def create(params)
      user_id = User.find_by_email(db, params['user'])['id']
      db.query(
        "INSERT INTO #{table} SET
          user_id = '#{user_id}',
          short_name = '#{params['short_name']}',
          name = '#{params['name']}';"
      )

      result = Forum.find_by_short_name(db, params['short_name'])
      Response.new(code: :ok, body: result).take
    end

    def details(params)
      result = Forum.find_by_short_name(db, params['forum'], params['related'])
      Response.new(code: :ok, body: result).take
    end

    def list_users(params)
      forum_id = Forum.find_by_short_name(db, params['forum'])['id']
      result = db.query(
        "SELECT * FROM Users
         INNER JOIN forum_authors a
         ON user.id = a.author_id
         WHERE a.forum_id = #{forum_id}
         #{ since(params['since_id'], 'a.author_id') }
         #{ order_by(params['order'], 'a.name') }
         #{ limit(params['limit']) };"
      )
      result.map { |row| User.get_by_id(row['id']) }
      raise result.count.inspect
    end

    def self.find_by_short_name(db, short_name, related = [])
      res = db.query(
        "SELECT * FROM #{table}
         WHERE short_name = '#{short_name}';"
      ).first

      if related.include? 'user'
        res['user'] = User.find_by_id(db, res['user_id'])
      else
        res['user'] = User.find_by_id(db, res['user_id'])['email']
      end
      res
    end

    def self.find_by_id(db, id, related = [])
      res = db.query(
        "SELECT * FROM #{table}
         WHERE id = '#{id}';"
      ).first

      if related.include? 'user'
        res['user'] = User.find_by_id(db, res['user_id'])
      else
        res['user'] = User.find_by_id(db, res['user_id'])['email']
      end
      res
    end
  end
end
