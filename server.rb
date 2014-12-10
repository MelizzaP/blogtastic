require 'sinatra'
require 'sinatra/reloader'
require 'pry-byebug'
require 'rack-flash'


require_relative 'lib/blogtastic.rb'

class Blogtastic::Server < Sinatra::Application
  configure do
    set :bind, '0.0.0.0'
    enable :sessions
    use Rack::Flash
  end

  before do
    if session['user_id']
      user_id = session['user_id']
      db = Blogtastic.create_db_connection 'blogtastic'
      @current_user = Blogtastic::UsersRepo.find db, user_id
    else
      @current_user = {'username' => 'anonymous', 'id' => 1}
    end
  end



  ###################################################################
  # DO NOT EDIT ANYTHING ABOVE THIS AREA
  ###################################################################

  # Refer to `lib/blogtastic/repos/users_repo.rb` to see how you can
  # save and find users to handle the authentication process.

  get '/signup' do
    erb :'/auth/signup'
  end

  post '/signup' do
    db = Blogtastic.create_db_connection 'blogtastic'
    user = Blogtastic::UsersRepo.save(db, params)
    session['user_id'] = user['id']
    redirect '/posts'
    
  end

  get '/signin' do
    erb :'/auth/signin'
  end

  post '/signin' do
    db = Blogtastic.create_db_connection 'blogtastic'
    user = Blogtastic::UsersRepo.find_by_name(db, params[:username])
    if user['password'] == params[:password]  
      session['user_id'] = user['id']
    end 
    redirect '/posts'
  end

  get '/logout' do
    session['user_id'] = nil
    redirect '/signin'
  end

  ###################################################################
  # DO NOT EDIT ANYTHING BELOW THIS AREA
  ###################################################################



  # landing
  get '/' do
    erb :index
  end

  # view all posts
  get '/posts' do
    db = Blogtastic.create_db_connection 'blogtastic'
    @posts = Blogtastic::PostsRepo.all db
    erb :'posts/index'
  end

  # new post page
  get '/posts/new' do
    erb :'posts/new'
  end

  # create a new post
  post '/posts' do
    post = {
      title:   params[:title],
      content: params[:content],
      user_id:    params[:user_id]
    }
    db = Blogtastic.create_db_connection 'blogtastic'
    Blogtastic::PostsRepo.save db, post

    redirect to '/posts'
  end

  # view a particular post
  get '/posts/:id' do
    db = Blogtastic.create_db_connection 'blogtastic'
    @post = Blogtastic::PostsRepo.find db, params[:id]
    @comments = Blogtastic::CommentsRepo.post_comments db, params[:id]
    @user = Blogtastic::UsersRepo.find db, @post['user_id']
    
    @comments.map do |c|
      comment_user = Blogtastic::UsersRepo.find db, c['user_id']
      c['user'] = comment_user['username']
    end

    erb :'posts/post'
  end

  # create a new comment on a post
  post '/posts/:post_id/comments' do
    comment = {
      content: params[:content],
      user_id: params[:user_id],
      post_id: params[:post_id]
    }
    db = Blogtastic.create_db_connection 'blogtastic'
    Blogtastic::CommentsRepo.save db, comment
    redirect to '/posts/' + params[:post_id]
  end

  # delete a post
  delete '/posts/:id' do
    db = Blogtastic.create_db_connection 'blogtastic'
    Blogtastic::CommentsRepo.destroy_all_comments(db, params[:id])
    Blogtastic::PostsRepo.destroy db, params[:id]
    redirect to '/posts'
  end
  
  #delete a comment on a post 
  delete '/posts/:post_id/comments/:id' do
    db = Blogtastic.create_db_connection 'blogtastic'
    Blogtastic::CommentsRepo.destroy(db, params[:id])
    redirect "/posts/"+params[:post_id]
  end
end
