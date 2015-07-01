require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra/json'

require 'cgi'
require 'mysql2'
require 'json'

require './models/helpers'
require './models/response'
require './models/system'
require './models/user'
require './models/forum'
require './models/thread'
require './models/post'

class App < Sinatra::Base
  register Sinatra::Namespace
  configure do
    set :root, '/db/api/'
  end

  helpers do
    def parse_body
      JSON.parse request.body.read
    rescue RuntimeError => e
      Response.new(:unprocessable, e.message).take
    end

    def parse_query
      return params unless params['related']
      params.merge('related' => CGI::parse(request.query_string)['related'])
    end
  end

  before do
    @params = request.post? ? parse_body : parse_query
  end

  namespace root do
    post 'clear/'  do json Model::System.new.clear end
    get  'status/' do json Model::System.new.status end
    namespace 'user/' do
      before do
        @user = Model::User.new
      end
      post 'create/' do json @user.create(@params) end
      get  'details/' do json @user.details(@params) end
      post 'updateProfile/'  do json @user.update_profile(@params) end
      post 'follow/' do json @user.follow(@params) end
      post 'unfollow/' do json @user.unfollow(@params) end
      get  'listFollowers/' do json @user.list_followers(@params) end
      get  'listFollowing/' do json @user.list_following(@params) end
    end

    namespace 'forum/' do
      before do
        @forum = Model::Forum.new
      end
      post 'create/' do json @forum.create(@params) end
      get  'details/' do json @forum.details(@params) end
      get  'listUsers/' do json @forum.list_users(@params) end
    end

    namespace 'thread/' do
      before do
        @thread = Model::Thread.new
      end
      post 'create/' do json @thread.create(@params) end
      get  'details/' do json @thread.details(@params) end
      post 'subscribe/' do json @thread.subscribe(@params) end
      post 'unsubscribe/' do json @thread.unsubscribe(@params) end
    end

    # namespace 'post/' do
    #   before do
    #     @post = Model::Post.new
    #   end
    #   post 'create/' do json @post.create(@params) end
    #   get  'details/' do json @post.details(@params) end
    # end
  end
end
