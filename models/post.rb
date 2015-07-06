module Model
  class Post
    attr_reader :db, :table

    def initialize
      @table = Post.table
      @db = Connector.db
    end

    def self.table
      "Posts"
    end

    def create(params)
      required_params = %w(date thread message user forum)
      optional = %w(parent isApproved isHighlighted isEdited isSpam isDeleted)

      escaped = Hash.new
      required_params.each do |key|
        escaped[key] = (params[key].is_a? String) ? db.escape(params[key]) : params[key]
      end

      optional.each do |key|
        escaped[key] = params[key] || false
      end
      escaped['parent'] = escaped['parent'] || "NULL"

      date = escaped['date']
      user_id = User.get_id(db, escaped['user'])
      forum_id = Forum.find_by_short_name(db, escaped['forum'])['id']
      thread_id = escaped['thread']

      thread = db.query(
        "SELECT * FROM Threads
         WHERE id = #{thread_id} AND
         forum_id = #{forum_id}").first
      db.query(
        "INSERT INTO Posts SET
         date           = '#{date}',
         message        = '#{escaped['message']}',
         parent_id      = #{escaped['parent']},
         user_id        = #{user_id},
         thread_id      = #{thread_id},
         isApproved     = #{escaped['isApproved']},
         isDeleted      = #{escaped['isDeleted']},
         isEdited       = #{escaped['isEdited']},
         isHighlighted  = #{escaped['isHighlighted']},
         isSpam         = #{escaped['isSpam']};"
      )
      post_id = db.last_id

      db.query(
        "UPDATE Threads SET
         count = count+1
         WHERE id = #{thread_id}"
      )

      result = db.query(
        "SELECT DATE_FORMAT(date, '%Y-%m-%d %H:%i:%s') AS date,
                '#{escaped['forum']}' as forum,
                id, isApproved, isDeleted, isEdited, isHighlighted,
                isSpam, message, parent_id as parent, thread_id as thread,
                '#{escaped['user']}' as user
         FROM Posts
         WHERE id = #{post_id}").first

      Response.new(code: :ok, body: result).take
    end

    def details(params)
      post_id = params['post']
      related = params['related']

      unless (related.nil?)
        user = related.include? 'user'
        forum = related.include? 'forum'
        thread = related.include? 'thread'
      end

      post = db.query("SELECT
        DATE_FORMAT(date, '%Y-%m-%d %H:%i:%s') AS date,
        dislikes, id, isApproved, isDeleted,
        isEdited, isHighlighted, isSpam,
        likes, message, parent_id as parent, points,
        thread_id as thread, user_id as user
        FROM Posts
        WHERE Posts.id = #{post_id}").first
      if (post.nil?)
        Response.new(code: :not_found, body: "Not Found").take
      else
        email = User.get_email(db, post['user'])
        short_name = Thread.find_by_id(db, post['thread'])['forum']
        post['user'] = user ? User.find_by_email(db, email) : email
        post['forum'] = forum ? Forum.find_by_short_name(db, short_name) : short_name
        post['thread'] = Thread.find_by_id(db, post['thread']) if thread
        Response.new(code: :ok, body: post).take
      end
    end

    def vote(params)
      begin
        post_id = params['post']
        vote = params['vote'] == 1 ? "likes" : "dislikes"

        begin
          db.query(
            "UPDATE Posts SET
             #{vote} = #{vote}+1,
             points = likes-dislikes
             WHERE id = '#{post_id}';"
          )

          result = db.query(
            "SELECT
            DATE_FORMAT(Threads.date, '%Y-%m-%d %H:%i:%s') AS date,
            Posts.dislikes, Forums.short_name as forum, Posts.id,
            Posts.isDeleted, isApproved, isEdited, isHighlighted,
            isSpam, Posts.likes, Posts.message, Posts.points,
            parent_id as parent,
            thread_id as thread, Users.email as user
            FROM Threads
            JOIN Users ON Threads.user_id = Users.id
            JOIN Forums ON Threads.forum_id = Forums.id
            WHERE Posts.id = '#{post_id}'").first
          Response.new(code: :ok, body: result).take
        rescue Mysql2::Error => e
          Response.new(code: :unknown, body: e.message).take
        end
      rescue RuntimeError => e
        Response.new(code: :bad_request, body: e.message).take
      end
    end

    def update(params)
      post_id = params['post']
      message = params['message']
      begin
        post = db.query(
          "SELECT * FROM Posts
           WHERE id='#{post_id}'").first
        if post.nil?
          Response.new(code: :not_found, body: "Post not found").take
        else
          db.query(
            "UPDATE Posts SET
             message='#{message}'
             WHERE id=#{post_id}")
          result = Post.find_by_id(db, post_id)
          Response.new(code: :ok, body: result).take
        end
      rescue Mysql2::Error => e
        Response.new(code: :unknown, body: "Unknown").take
      end
    end

    def remove(params)
      post_id = params['post']
      begin
        post = db.query(
          "SELECT * FROM Posts
           WHERE id='#{post_id}'").first
        if post.nil?
          Response.new(code: :not_found, body: "Post not found").take
        else
          db.query(
            "UPDATE Posts SET isDeleted=true
             WHERE id='#{post_id}'")
          db.query (
            "UPDATE Threads SET
             count = count-1
             WHERE id = '#{post['thread_id']}'")
          result = { "post" => post_id }
          Response.new(code: :ok, body: result).take
        end
      rescue Mysql2::Error => e
        Response.new(code: :unknown, body: "Unknown").take
      end
    end

    def restore(params)
      begin
        post_id = params['post']
        begin
          code = Code.ok
          post = @client.query("SELECT * FROM Posts WHERE id='#{post_id}'").first
          if (post.nil?)
            return Response.new(code: :not_found, body: "Post not found").take
          else
            @client.query("UPDATE Posts SET isDeleted=false WHERE id='#{post_id}'")
            @client.query ("UPDATE Threads SET count = count+1
                            WHERE id = '#{post['thread_id']}'")
            response = {:post => post_id}
          end
        rescue Mysql2::Error => e
          Response.new(code: :unknown, body: e.message).take
        end
      rescue RuntimeError => e
        Response.new(code: :bad_request, body: e.message).take
      end
      Response.new(code: :ok, body: response).take
    end

    def list(params)
      begin
        short_name = @client.escape(params['forum']) if params.include? 'forum'
        thread_id = params['thread'] if params.include? 'thread'

        unless thread_id.nil? ^ short_name.nil?
          return Response.new(code: :unprocessable, body: "Invalid data").take
        end

        limit = params.include?('limit') ? " LIMIT #{params['limit']}" : ''
        order = params.include?('order') ? " #{params['order']}" : 'desc'
        since = params.include?('since') ? " AND Posts.date >= '#{params['since']}' " : ''

        begin
          code = Code.ok
          if (thread_id)
            thread = @client.query("SELECT * FROM Threads WHERE id = '#{thread_id}'")
            if (thread.nil?)
              return Response.new(code: :not_found, body: "Thread not found").take
            end
            where = " WHERE Threads.id = '#{thread_id}' "
          else
            forum_id = Forum.getId(@client, short_name)
            if (forum_id.nil?)
              return Response.new(code: :not_found, body: "Forum not found").take
            end
            where =  " WHERE Forums.id = '#{forum_id}' "
          end
          posts = @client.query("SELECT
            DATE_FORMAT(Posts.date, '%Y-%m-%d %H:%i:%s') AS date,
            Posts.dislikes, Forums.short_name as forum, Posts.id,
            Posts.isApproved, Posts.isDeleted, Posts.isEdited,
            Posts.isHighlighted, Posts.isSpam, Posts.likes,
            Posts.message, Posts.parent_id as parent,
            Posts.points, Posts.thread_id as thread,
            Users.email as user
            FROM Posts
            JOIN Users ON Posts.user_id = Users.id
            JOIN Threads ON Threads.id = Posts.thread_id
            JOIN Forums ON Forums.id = Threads.forum_id
            #{where} #{since}
            ORDER BY date #{order} #{limit}")
          response = posts.map{ |post| post }
        rescue Mysql2::Error => e
          Response.new(code: :unknown, body: e.message).take
        end
      rescue RuntimeError => e
        Response.new(code: :bad_request, body: e.message).take
      end
      Response.new(code: :ok, body: response).take
    end

    def self.find_by_id(db, id, related = [])
      res = db.query(
        "SELECT
          DATE_FORMAT(Posts.date, '%Y-%m-%d %H:%i:%s') AS date,
          Posts.dislikes, Forums.short_name as forum, Posts.id,
          Posts.isApproved, Posts.isDeleted, Posts.isEdited,
          Posts.isHighlighted, Posts.isSpam, Posts.likes,
          Posts.message, Posts.parent_id as parent,
          Posts.points, Posts.thread_id as thread,
          Users.email as user
          FROM Posts
          JOIN Users ON Posts.user_id = Users.id
          JOIN Threads ON Threads.id = Posts.thread_id
          JOIN Forums ON Forums.id = Threads.forum_id
          WHERE Posts.id = '#{id}'").first
    end
  end
end
