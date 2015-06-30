module Model
  class User
    attr_reader :db

    def initialize
      @db = Connector.db
    end

    def create(params)
      db.query(
        "INSERT INTO user SET
          email = '#{params['email']}',
          username = '#{params['username']}',
          about = '#{params['about']}',
          name = '#{params['name']}',
          isAnonymous = #{params['isAnonymous']};"
        )
      puts db.last_id.inspect
    rescue Mysql2::Error => e
      puts e.message.inspect
      puts e.error_number.inspect
    end


    def details(params)
      user = db.query(
        "SELECT * FROM user
         WHERE email = '#{params['user']}';"
        ).first
    end
  end
end
