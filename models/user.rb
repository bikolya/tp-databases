module Model
  class User
    include Model::Helpers
    attr_reader :db, :table

    def initialize(attrs = {})
      @table = User.table
      @db = Connector.db
    end

    def self.table
      "Users"
    end

    def create(params)
      db.query(
        "INSERT INTO #{table} SET
          email = '#{params['email']}',
          username = '#{params['username']}',
          about = '#{params['about']}',
          name = '#{params['name']}',
          isAnonymous = #{params['isAnonymous']};"
        )

      result = User.find_by_email(db, params['email'])
      Response.new(code: :ok, body: result).take
    rescue Mysql2::Error => e
      Response.new(code: :already_exists, body: e.message).take
    end

    def details(params)
      result = User.find_by_email(db, params['user'])
      Response.new(code: :ok, body: result).take
    end

    def update_profile(params)
      user_id = User.get_id(db, params['user'])
      db.query(
        "UPDATE #{table} SET
         name = '#{params['name']}',
         about = '#{params['about']}'
         WHERE id = '#{user_id}';"
      )

      result = User.find_by_email(db, params['user'])
      Response.new(code: :ok, body: result).take
    end

    def follow(params)
      follower_id = User.get_id(db, params['follower'])
      followee_id = User.get_id(db, params['followee'])
      db.query(
        "INSERT IGNORE INTO Followers SET
          follower_id = '#{follower_id}',
          followee_id = '#{followee_id}';"
      )

      result = User.find_by_id(db, follower_id)
      Response.new(code: :ok, body: result).take
    end

    def unfollow(params)
      follower_id = User.get_id(db, params['follower'])
      followee_id = User.get_id(db, params['followee'])
      db.query(
        "DELETE FROM Followers
         WHERE follower_id = '#{follower_id}'
         AND followee_id = '#{followee_id}';"
      )

      result = User.find_by_id(db, follower_id)
      Response.new(code: :ok, body: result).take
    end

    def list_followers(params)
      user_id = User.get_id(db, params['user'])
      followers = db.query(
        "SELECT Users.email as email
         FROM Followers
         JOIN Users ON follower_id = Users.id
         WHERE followee_id = '#{user_id}'
         #{ since(params['since_id'], 'id') }
         #{ order_by(params['order'], 'name') }
         #{ limit(params['limit']) };"
      )
      result = followers.map do |row|
        row['email'] = User.find_by_email(db, row['email'])
      end
      Response.new(code: :ok, body: result).take
    end

    def list_following(params)
      user_id = User.get_id(db, params['user'])
      followees = db.query(
        "SELECT Users.email as email
         FROM Followers
         JOIN Users ON followee_id = Users.id
         WHERE follower_id = '#{user_id}'
         #{ since(params['since_id'], 'id') }
         #{ order_by(params['order'], 'name') }
         #{ limit(params['limit']) };"
      )
      result = followees.map do |row|
        row['email'] = User.find_by_email(db, row['email'])
      end
      Response.new(code: :ok, body: result).take
    end

    def list_posts(params)
      email = params['user']
      user_id = User.get_id(db, email)
      if (user_id.nil?)
        Response.new(code: :not_found, body: "User not found").take
      else
        posts = db.query(
          "SELECT
          DATE_FORMAT(date, '%Y-%m-%d %H:%i:%s') AS date,
          dislikes,
          id,
          isApproved,
          isDeleted,
          isEdited,
          isHighlighted,
          isSpam,
          likes,
          message,
          parent_id as parent,
          points,
          thread_id as thread
          FROM Posts
          WHERE user_id = '#{user_id}'
          #{ since(params['since'], 'date') }
          #{ order_by(params['order'], 'date') }
          #{ limit(params['limit']) };")

        result = posts.each do |post|
          post['user'] = email;
          post['forum'] = Thread.find_by_id(db, post['thread'])['forum']
        end
        Response.new(code: :ok, body: result).take
      end
    end

    def self.find_by_email(db, email)
      res = db.query(
        "SELECT * FROM #{table}
         WHERE email = '#{email}';"
      ).first
      raise RuntimeError if res.nil?
      res['followers'] = User.get_followers(db, res['id'])
      res['following'] = User.get_followees(db, res['id'])
      res['subscriptions'] = User.get_subscriptions(db, res['id'])
      res
    end

    def self.find_by_id(db, id)
      res = db.query(
        "SELECT * FROM #{table}
         WHERE id = '#{id}';"
      ).first
      raise RuntimeError if res.nil?
      res['followers'] = User.get_followers(db, res['id'])
      res['following'] = User.get_followees(db, res['id'])
      res['subscriptions'] = User.get_subscriptions(db, res['id'])
      res
    end

    def self.get_id(db, email)
      User.find_by_email(db, email)['id']
    end

    def self.get_email(db, id)
      User.find_by_id(db, id)['email']
    end

    def self.get_followers(db, id)
      res = db.query(
        "SELECT email FROM #{table} u
         INNER JOIN Followers f
         ON f.follower_id = u.id
         WHERE f.followee_id = '#{id}';"
      )
      res.map { |row| row['email'] }
    end

    def self.get_followees(db, id)
      res = db.query(
        "SELECT sql_no_cache email FROM #{table} u
         INNER JOIN Followers f
         ON f.followee_id = u.id
         WHERE f.follower_id = '#{id}';"
      )
      res.map { |row| row['email'] }
    end

    def self.get_subscriptions(db, id)
      res = db.query(
        "SELECT thread_id FROM Subscriptions
         WHERE user_id = '#{id}';"
      )
      res.map { |row| row['thread_id'] }
    end
  end
end
