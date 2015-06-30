require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra/json'

require 'mysql2'
require 'json'

require './models/user'

class App < Sinatra::Base
  register Sinatra::Namespace
  configure do
    set :root, '/db/api/'
  end

  helpers do
    def parse_body
      JSON.parse request.body.read
    end
  end

  before do
    @params = request.post? ? parse_body : params
  end

  namespace root do
    namespace 'user/' do
      before do
        @user = Model::User.new
      end
      post 'create/'  do json @user.create(@params) end
      get  'details/' do json @user.details(@params) end
    end
  end
end

