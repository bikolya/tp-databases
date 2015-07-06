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

    def list_posts(params)
      short_name = params['forum']
      related = params['related']
      unless related.nil?
        thread_details = related.include? 'thread'
        forum_details = related.include? 'forum'
        user_details = related.include? 'user'
      end
      forum = Forum.find_by_short_name(db, short_name)
      if forum.nil?
        Response.new(code: :not_found, body: "Forum not found").take
      else
        posts = db.query(
          "SELECT
          DATE_FORMAT(Posts.date, '%Y-%m-%d %H:%i:%s') AS date,
          Posts.dislikes as dislikes,
          Forums.short_name as forum,
          Posts.id as id,
          isApproved,
          Posts.isDeleted,
          isEdited,
          isHighlighted,
          isSpam,
          Posts.likes,
          Posts.message,
          parent_id as parent,
          Posts.points,
          Threads.id as thread,
          Posts.user_id as user
          FROM Posts JOIN Threads
          ON Posts.thread_id = Threads.id
          JOIN Forums ON Threads.forum_id = Forums.id
          WHERE Forums.short_name = '#{short_name}'
          #{ since(params['since'], 'Posts.date') }
          #{ order_by(params['order'], 'date') }
          #{ limit(params['limit']) };"
        )

        result = posts.each do |post|
          email = User.get_email(db, post['user'])
          post['user'] = user_details ? User.find_by_email(db, email) : email
          post['forum'] = Forum.find_by_short_name(db, post['forum']) if forum_details
          post['thread'] = Thread.find_by_id(db, post['thread']) if thread_details
        end
        Response.new(code: :ok, body: result).take
      end
    end

    def list_users(params)
      short_name = params['forum']
      begin
        forum = Forum.find_by_short_name(db, short_name)['id']
        if forum.nil?
          Response.new(code: :not_found, body: "Forum not found").take
        else
          users = db.query(
            "SELECT DISTINCT
              Users.email as email,
              Users.name
              FROM Users
              JOIN Posts ON Posts.user_id = Users.id
              JOIN Threads ON Posts.thread_id = Threads.id
              JOIN Forums ON Threads.forum_id = Forums.id
              WHERE Forums.short_name = '#{short_name}'
              #{ since(params['since_id'], 'Users.id') }
              #{ order_by(params['order'], 'name') }
              #{ limit(params['limit']) };")
          result = users.map do |user|
            user = User.find_by_email(db, user['email'])
            user
          end
          Response.new(code: :ok, body: result).take
        end
      rescue RuntimeError => e
        Response.new(code: :unknown, body: "Unknown").take
      end
    end

    def list_threads(params)
      begin
        short_name = params['forum']

        limit = params.include?('limit') ? " LIMIT #{params['limit']}" : ''
        order = params.include?('order') ? " #{params['order']}" : 'desc'
        since = params.include?('since') ? " AND date >= '#{params['since']}' " : ''

        related = params['related']
        unless related.nil?
          forum_details = related.include? 'forum'
          user_details = related.include? 'user'
        end

        begin
          forum = Forum.find_by_short_name(db, short_name)
          if (forum.nil?)
            return Response.new(code: :not_found, body: "Forum not found").take
          else
            threads = db.query("SELECT
              DATE_FORMAT(Threads.date, '%Y-%m-%d %H:%i:%s') AS date,
              Threads.dislikes as dislikes,
              short_name as forum,
              Threads.id as id,
              Threads.isClosed,
              Threads.isDeleted,
              likes,
              Threads.message,
              Threads.points,
              Threads.count as posts,
              Threads.slug as slug,
              Threads.title as title,
              Threads.user_id as user
              FROM Forums JOIN Threads
              ON Forums.id = Threads.forum_id
              WHERE Forums.short_name = '#{short_name}' #{since}
              ORDER BY date #{order} #{limit}")
            response = threads.map do |thread|
              email = User.find_by_id(db, thread['user'])
              thread['user'] = user_details ? User.getUserDetails(db, email) : email
              thread['forum'] = Forum.find_by_id(db, thread['forum']) if forum_details
              thread
            end
          end
        rescue Mysql2::Error => e
          Response.new(code: :unknown, body: e.message).take
        end
      rescue RuntimeError => e
        Response.new(code: :bad_request, body: e.message).take
      end
      Response.new(code: :ok, body: response).take
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
