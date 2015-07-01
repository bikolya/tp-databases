module Model
  class Thread
    include Model::Helpers
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

    def open(params)
      db.query(
        "UPDATE Threads SET
          isClosed=false WHERE id='#{params['thread']}'"
      )
      result = params
      Response.new(code: :ok, body: result).take
    end

    def close(params)
      db.query(
        "UPDATE Threads SET
          isClosed=true WHERE id='#{params['thread']}'"
      )
      result = params
      Response.new(code: :ok, body: result).take
    end

    def subscribe(params)
      email = params['user']
      thread_id = params['thread']
      begin
        user_id = User.get_id(db, email)
        thread = db.query(
          "SELECT * FROM Threads
          WHERE id = #{thread_id}").first
          if (user_id.nil? or thread.nil?)
          Response.new(code: :not_found, body: "Not found").take
        else
          db.query(
            "INSERT IGNORE INTO Subscriptions SET
             thread_id = #{thread_id},
             user_id = #{user_id}")
          result = {"thread" => thread_id, "user" => email}
          Response.new(code: :ok, body: result).take
        end
      rescue RuntimeError => e
        Response.new(code: :unknown, body: e.message).take
      end
    end

    def unsubscribe(params)
      email = params['user']
      thread_id = params['thread']
      user_id = User.get_id(db, email)
      begin
        db.query(
          "DELETE FROM Subscriptions
           WHERE thread_id = #{thread_id}
           AND user_id = #{user_id}")
          result = {"thread" => thread_id, "user" => email}
        Response.new(code: :ok, body: result).take
      rescue RuntimeError => e
        Response.new(code: :unknown, body: e.message).take
      end
    end

    def list_posts(params)
      thread = Thread.find_by_id(db, params['thread'])
      if (thread.nil?)
        Response.new(code: :not_found, body: "Thread not found").take
      else
        posts = db.query(
            "SELECT
            DATE_FORMAT(Posts.date, '%Y-%m-%d %H:%i:%s') AS date,
            Posts.dislikes as dislikes, short_name as forum,
            Posts.id as id, isApproved, Posts.isDeleted,
            isEdited, isHighlighted, isSpam,
            Posts.likes, Posts.message, parent_id as parent,
            Posts.points, Threads.id as thread,
            Posts.user_id as user
            FROM Posts JOIN Threads
            ON Posts.thread_id = Threads.id
            JOIN Forums ON Threads.forum_id = Forums.id
            WHERE Posts.thread_id = #{params['thread']}
            #{ since(params['since'], 'Posts.date') }
            #{ order_by(params['order'], 'date') }
            #{ limit(params['limit']) };"
        )
        result = posts.each { |p| p['user'] = User.get_email(db, p['user'])}
        Response.new(code: :ok, body: result).take
      end
    end

    def list(params)
      email = params['user']
      short_name = params['forum']
      unless email.nil? ^ short_name.nil?
        Response.new(code: :unprocessable, body: "Invalid data").take
      end

      begin
        if email
          user_id = User.get_id(db, email)
          if user_id.nil?
            return Response.new(code: :not_found, body: "User not found").take
          end
          where = " WHERE Users.id = '#{user_id}' "
        else
          forum_id = Forum.find_by_short_name(db, short_name)['id']
          if forum_id.nil?
            return Response.new(code: :not_found, body: "User not found").take
          end
          where =  " WHERE Forums.id = '#{forum_id}' "
        end
        threads = db.query(
          "SELECT
          DATE_FORMAT(Threads.date, '%Y-%m-%d %H:%i:%s') AS date,
          Threads.dislikes, Forums.short_name as forum, Threads.id,
          Threads.isClosed, Threads.isDeleted, Threads.likes,
          Threads.message, Threads.points, Threads.count as posts,
          Threads.slug, Threads.title, Users.email as user
          FROM Threads
          JOIN Users ON Threads.user_id = Users.id
          JOIN Forums ON Threads.forum_id = Forums.id
          #{ since(params['since'], 'Threads.date') }
          #{ order_by(params['order'], 'date') }
          #{ limit(params['limit']) };")
        result = threads.to_a
        Response.new(code: :ok, body: result).take
      rescue Mysql2::Error => e
        Response.new(code: :unknown, body: "Unknown error").take
      end
    end

    def update(params)
      message = params['message']
      slug = params['slug']
      thread_id = params['thread']
      begin
        db.query (
          "UPDATE Threads SET
           message = '#{message}',
           slug = '#{slug}'
           WHERE id = '#{thread_id}'")
        result = db.query(
          "SELECT
          DATE_FORMAT(Threads.date, '%Y-%m-%d %H:%i:%s') AS date,
          Threads.dislikes, Forums.short_name as forum, Threads.id,
          Threads.isClosed, Threads.isDeleted, Threads.likes,
          Threads.message, Threads.points, Threads.count as posts,
          Threads.slug, Threads.title, Users.email as user
          FROM Threads
          JOIN Users ON Threads.user_id = Users.id
          JOIN Forums ON Threads.forum_id = Forums.id
          WHERE Threads.id = '#{thread_id}'").first
        Response.new(code: :ok, body: result).take
      rescue Mysql2::Error => e
        Response.new(code: :unknown, body: e.message).take
      end
    rescue Mysql2::Error => e
      Response.new(code: :unvalid, body: e.message).take
    end

    def remove(params)
      id = params['thread']
      db.query(
        "UPDATE Threads SET
         isDeleted=true,
         count=0
         WHERE id='#{id}'")
      posts = db.query(
        "SELECT * FROM Posts
         WHERE thread_id = '#{id}'")
      posts.each do |post|
        db.query(
          "UPDATE Posts SET isDeleted=true
          WHERE id='#{post['id']}'")
      end
      Response.new(code: :ok, body: {"thread" => id}).take
    end

    def restore(params)
      id = params['thread']
      posts = db.query(
        "SELECT * FROM Posts
        WHERE thread_id = '#{id}'")
      posts.each do |post|
        db.query(
          "UPDATE Posts SET isDeleted=false
          WHERE id='#{post['id']}'")
      end
      db.query "UPDATE Threads SET
                     isDeleted=false,
                     count=#{posts.size}
                     WHERE id='#{id}'"
      Response.new(code: :ok, body: {"thread" => id}).take
    end

    def vote(params)
      thread_id = params['thread']
      vote = params['vote'] == 1 ? "likes" : "dislikes"

      begin
        db.query(
          "UPDATE Threads SET
           #{vote} = #{vote}+1,
           points = likes-dislikes
           WHERE id = '#{thread_id}';"
        )

        result = db.query(
          "SELECT
          DATE_FORMAT(Threads.date, '%Y-%m-%d %H:%i:%s') AS date,
          Threads.dislikes, Forums.short_name as forum, Threads.id,
          Threads.isClosed, Threads.isDeleted, Threads.likes,
          Threads.message, Threads.points, Threads.count as posts,
          Threads.slug, Threads.title, Users.email as user
          FROM Threads
          JOIN Users ON Threads.user_id = Users.id
          JOIN Forums ON Threads.forum_id = Forums.id
          WHERE Threads.id = '#{thread_id}'").first
        Response.new(code: :ok, body: result).take
      rescue Mysql2::Error => e
        Response.new(code: :unknown, body: e.message).take
      end
    rescue RuntimeError => e
      Response.new(code: :bad_request, body: e.message).take
    end

    def self.find_by_id(db, id, related = [])
      related ||= []
      res = db.query(
        "SELECT * FROM #{table}
         WHERE id = '#{id}';"
      ).first
      raise RuntimeError if res.nil?
      res['date'] = res['date'].strftime('%Y-%m-%d %H:%M:%S')
      posts = db.query("SELECT * FROM Posts WHERE thread_id = '#{id}'")
      res['posts'] = posts.count
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
