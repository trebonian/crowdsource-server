#!/usr/bin/env ruby
require 'rubygems'
require 'dm-core'
require 'dm-validations'
require 'dm-migrations'
require 'logger'
require 'haml'
require 'models'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/db/development.db")
DataMapper::Logger.new(STDOUT, :debug)

User.auto_migrate!
Chip.auto_migrate!
Layer.auto_migrate!
Tile.auto_migrate!
Submission.auto_migrate!
Line.auto_migrate!
