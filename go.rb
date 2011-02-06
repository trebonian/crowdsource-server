require 'rubygems'
require 'sinatra'
require 'digest/sha1'
require 'dm-core'
require 'dm-validations'
require 'haml'
require 'sass'
require 'models'
require 'time'
require 'pp'
require 'fast-aes'
@@secret = FastAES.new("changemechangmec")
enable :sessions

#temp db hack 
##http://www.mail-archive.com/datamapper@googlegroups.com/msg00263.html
class DataObjects::Sqlite3::Command
  alias original_execute_non_query execute_non_query
  alias original_execute_reader execute_reader

  def execute_non_query(*args)
    try_again = 0
    begin
      original_execute_non_query(*args)
    rescue DataObjects::SQLError => e
      raise unless e.message =~ /locked/ || e.message =~ /busy/

      if try_again < 10
        try_again += 1
        #VipLog.debug "locked or busy - retrying (#{try_again})"
        retry
      else
        raise
      end
    end
  end

  def execute_reader(*args)
    try_again = 0
    begin
      original_execute_reader(*args)
    rescue DataObjects::SQLError => e
      raise unless e.message =~ /locked/ || e.message =~ /busy/

      if try_again < 5
        try_again += 1
        retry
      else
        raise
      end
    end
  end
end



# SASS stylesheet
get '/stylesheets/style.css' do
  headers 'Content-Type' => 'text/css; charset=utf-8'
  sass :style
end

### Index
get '/' do
  authorized?
  haml :index
end

########################
#routing 
get '/user/*' do
  protected!
  pass  
end
post '/user/*' do
  protected!
  pass  
end
put '/user/*' do
end
get '/admin/*' do
  admin!
  pass
end
post '/admin/*' do
  admin!
  pass
end
########################
#login
get '/register' do
  haml :register
end

post '/register' do
  username = params[:username].match(/[A-Za-z0-9]*/).to_s
  email = params[:email].match(/[\.A-Za-z0-9]*@[A-Za-z0-9\.]*/).to_s
    
  if(params[:password] == params[:password2])
    unless User.first(:name => username)
      u = User.create
      u.name = username
      u.email = email
      u.admin = false
      u.points = 0
      u.location = params[:location]
      u.real_name = params[:realname]
      u.salt = rand_string(10)
      u.hashpass = Digest::SHA1.hexdigest(params[:password]+u.salt)
      puts "SAVING USER"
      error("Something went wrong") if not u.save
    else
      error("User already exists")
    end
  else
    error("Your password confirmation did not match")
  end
  
  haml :index
end

post '/login' do
  username = params[:username]
  password = params[:password]
  
  u = User.first(:name => username)                
  unless u == nil
    if u.hashpass == Digest::SHA1.hexdigest(password+u.salt)
      #create the users session
      blob = "#{Time.now.to_i}\xff#{username}"
      session["hash"] = Digest::SHA1.digest(blob) + @@secret.encrypt(blob)
      @user = u
    else
      error("Wrong credentials buddy")
    end
  else
    error("Wrong credentials buddy")
  end

  haml :index
end

get '/logout' do
	session["hash"] = nil
	redirect '/'
end
########################
#user management
get '/user/changepass' do
  haml :changepass
end

post '/user/changepass' do
  if @user.hashpass == Digest::SHA1.hexdigest(params[:oldpass]+@user.salt)
#    if params[:newpass].any? and (params[:newpass] == params[:newpass2])
     if (params[:newpass] == params[:newpass2])
      #note -> salt is being reused
      @user.hashpass = Digest::SHA1.hexdigest(params[:newpass]+@user.salt)
      if @user.save
        @errors = "Successfully changed password"
      else
        @errors = "Failed to save, contact admin"
      end
    else
      @errors = "New passwords dont match"
    end
  else
    @errors = "Wrong password"
  end
  haml :changepass
end


########################
### admin - Users
get '/admin/user/list' do
  @users = User.all
  haml :user_list
end

get '/admin/user/edit/:id' do
  if params[:id] == "new"
    @target = User.create
  else
    @target = User.first(:id => params[:id])
  end
  haml :user_edit
end

post '/admin/user/edit' do
  @target = User.first(:id => params[:id])
  data = params[:user]
  
  @target.name = data[:name] 
  @target.email = data[:email]
  
  if data[:admin] == "on"
    if @target.name != "admin"
      @target.admin = !@target.admin
    else
      @errors = "can not toggle admin user"
    end
  end
  
  if data[:reset_password]
    puts "would reset password"
  end

  @errors = "Something went wrong" if not @target.save

  @users = User.all
  haml :user_list
end

get '/admin/user/delete/:id' do
  @target = User.first(:id => params[:id])
  unless @target.name == 'admin'
    @target.destroy
  end
  redirect '/admin/user/list'
end

########################
### Chips, Layers, and Tiles
get '/user/chips' do
  @chips = Chip.all
  haml :chip_list
end

get '/user/chip/:id' do
  @chip = Chip.first(:id =>params[:id])
  haml :chip_view
end

get '/user/chip/:id/:layer' do
  @chip = Chip.first(:id =>params[:id])
  @layer = Layer.first(:id => params[:layer])
  session[:x] ||= 0
  session[:y] ||= 0
  haml :chip_view
end

get '/user/chip/:id/:layer/:direction' do
  @chip = Chip.first(:id =>params[:id])
  @layer = Layer.first(:id => params[:layer])

  session[:x] ||= 0
  session[:y] ||= 0

  if params[:direction] == "left"
    session[:x] -= 1
  elsif params[:direction] == "right"
    session[:x] += 1
  elsif params[:direction] == "up"
    session[:y] -= 1
  elsif params[:direction] == "down"
    session[:y] += 1
  elsif params[:direction] == "start"
    session[:x] = 0
    session[:y] = 0
  end
  haml :chip_view
end


get '/admin/chip/edit/:id' do
  if params[:id] == "new"
    @target = Chip.create
  else
    @target = Chip.first(:id => params[:id])
  end
  haml :chip_edit
end

post '/admin/chip/edit' do
  @target = Chip.first(:id => params[:id])
  data = params[:chip]

  @target.name = data[:name]
  @target.wikiURL = data[:wikiURL]
  @target.description = data[:description]
  @target.maxx = data[:maxx]
  @target.maxy = data[:maxy]
  @errors = "Something went wrong" if not @target.save
  redirect '/user/chips'
end

get '/admin/chip/delete/:id' do
  @target = Chip.first(:id => params[:id])
  @target.destroy
  redirect '/user/chips'
end

get '/admin/layer/edit/:chipid/:id' do
  chip = Chip.first(:id =>params[:chipid])
  if params[:id] == "new"
    @target = Layer.create
    @target.chip_id = chip.id
  else
    @target = Layer.first(:id => params[:id])
  end
  haml :layer_edit
end

post '/admin/layer/edit' do
  @target = Layer.first(:id => params[:id])
  data = params[:layer]

  @target.name = data[:name]
  @target.chip_id = data[:chip_id]
  @target.itype = data[:itype]
  @target.short_text = data[:short_text]
  @target.long_text = data[:long_text]
  @target.thumbnail = data[:thumbnail]
  @errors = "Something went wrong" if not @target.save
  redirect '/user/chips'
end

get '/admin/layer/delete/:id' do
  @target = Layer.first(:id => params[:id])
  @target.destroy
  redirect '/user/chips'
end


get '/user/tile/:layer_id/:x/:y' do
  @tile = Tile.first(:layer_id => params[:layer_id], 
                    :x_coord => params[:x],
                    :y_coord => params[:y])
  
  if @tile
    layer = Layer.first(:id=>@tile.layer_id)
  else
    redirect '/tiles/missing.png'
  end
  
  redirect "/tiles/#{layer.chip_id}/#{@tile.y_coord}-#{@tile.x_coord}#{layer.itype}.png"
end

=begin
class Tile
  include DataMapper::Resource
  property :id,       Serial
  property :layer_id, Integer
  property :minx,     Integer
  property :miny,     Integer
  property :sizex,    Integer
  property :sizey,    Integer

  property :jpeg,       String
  property :png,        String
  property :thumbnail,  String

end
=end
########################
### Game and Submissions
get '/user/game' do
  haml :game_index
end

get '/user/game/new_tile' do
  #pick a random layer on a random chip
  @layer = (Layer.all.sort_by {rand}).first
  @tile = (Tile.all(:layer_id=>@layer.id).sort_by {rand}).first
  session[:x] = @tile.x_coord
  session[:y] = @tile.y_coord
  haml :game_view
end

put '/submission/:user_id/:tile_id' do
  tile = Tile.first(params[:tile_id])
  user = User.first(params[:user_id])
  
  if tile and user
    data = request.body.read
    puts tile
    s = Submission.create
    s.user_id = user.id
    s.tile_id = tile.id
    s.rawdata = data
    s.quality_factor = 0
    s.initial_score = 0
    s.bonus = 0
    if not s.save
      redirect '/', 500
    end
  else
    redirect '/', 400 #bad request
  end
  
  "OK"  
end

#  users submit annotations for each tile

helpers do
  def error(str)
    @errors = str
  end

  def rand_string(n)
    alphabet = (('a'..'z').to_a+('A'..'Z').to_a+('0'..'9').to_a)
    return (0...n).map{ alphabet.to_a[rand(62)] }.join
  end

  def admin!  
    unless authorized? and @user.admin
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def protected!
    unless authorized?
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    #TODO->switch to HMAC

    #currently doing HASH|CRYPTED
    # H(decrypt(CRYPTED)) == HASH
    return false if not session["hash"]

    text = session["hash"][20..-1]
    hash = session["hash"][0..19]
    #stateless sessions. 
    data = @@secret.decrypt(text)

    if Digest::SHA1.digest(data) == hash
      expiration, username = data.split("\xff",2)
      #1 day sessions
      if Time.now.to_i - expiration.to_i < 24*60*60
        @user = User.first(:name => username)
        return true
      end
    end
    false
  end
end
