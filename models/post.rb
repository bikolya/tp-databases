module Model
  class Thread
    attr_reader :db

    def initialize
      @db = Connector.db
    end

    def create(params)
      author_id = User.get_id(db, params['user'])
      forum_id = Forum.find_by_short_name(db, params['forum'])['id']
      db.query(
        "INSERT INTO thread SET
          author_id = '#{author_id}',
          forum_id = '#{forum_id}',
          thread_id = '#{thread}',
          title = '#{params['title']}',
          slug = '#{params['slug']}',
          isDeleted = #{params['isDeleted']},
          isApproved = #{params['isApproved']},
          isEdited = #{params['isEdited']},
          isHighlighted = #{params['isHighlighted']},
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

    def self.find_by_id(db, id, related = [])
      res = db.query(
        "SELECT * FROM thread
         WHERE id = '#{id}';"
      ).first
      res['date'] = res['date'].strftime('%Y-%m-%d %H:%M:%S')

      if related.include? 'user'
        res['user'] = User.find_by_id(db, res['author_id'])
      else
        res['user'] = User.find_by_id(db, res['author_id'])['email']
      end

      if related.include? 'forum'
        res['forum'] = Forum.find_by_id(db, res['forum_id'])
      else
        res['forum'] = Forum.find_by_id(db, res['forum_id'])['short_name']
      end

      if related.include? 'thread'
        res['thread'] = User.find_by_id(db, res['thread_id'])
      end
      res
    end
  end
end
