require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/db/development.db")

### MODELS
class User
  include DataMapper::Resource
  property :id,         Serial
  property :name,       String, :unique_index => true
  property :real_name,  String
  property :email,      String, :unique_index => true
  property :location,   String
  property :salt,       String
  property :hashpass,   String  # 'hash' is a restricted property
  property :points,     Integer
  property :promotion_level,     Integer
  property :quality_factor,     Integer
  property :admin,      Boolean 

  #team information
  property :team_id,  Integer
  
  property :created_at, DateTime
end

class Chip
  include DataMapper::Resource
  property :id,           Serial
  property :name,         String
  property :wikiURL,      String
  property :description,  String
  property :maxx,         Integer
  property :maxy,         Integer

  property :created_at, Time
end

class Layer
  include DataMapper::Resource
  property :id,           Serial
  property :name,         String
  property :chip_id,      Integer
  property :itype,        String
  property :short_text,   String
  property :long_text,    String
  property :thumbnail,    String
  
  property :created_at, Time
end

class Tile
  include DataMapper::Resource
  property :id,       Serial
  property :layer_id, Integer
  
  #current tile mechanism
  property :x_coord,     Integer
  property :y_coord,     Integer

  #this represents some different mapping:
  property :minx,     Integer
  property :miny,     Integer
  property :sizex,    Integer
  property :sizey,    Integer

  property :jpeg,       String
  property :png,        String
  property :thumbnail,  String

end

=begin
What is this?
class Photolayer
  include DataMapper::Resource
  property :id,      Serial
  property :name,    String
end
=end

class Submission
  include DataMapper::Resource
  property :id,             Serial
  property :user_id,        Integer
  property :tile_id,        Integer
  property :rawdata,        String
  property :quality_factor, Integer
  property :initial_score,  Integer
  property :bonus,          Integer
  

  property :created_at, Time
end

class Line
  include DataMapper::Resource
  property :id,             Serial
  property :submission_id,  Integer
  property :data,           String
  property :created_at, Time
end
