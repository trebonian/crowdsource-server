#!/usr/bin/env ruby
require 'rubygems'
require 'digest/sha1'
require 'termios'
require 'models'
require 'pp'
require 'pony'

###
def help
  puts "---_User Management_---\nUsage:\n"
  puts "a(dd) username"
  puts "d(el) username"
  puts "m(ak) username -> make admin"
  puts "unm   username -> unmake admin"
  puts "l(ist)"
end

#http://aspn.activestate.com/ASPN/Mail/Message/ruby-talk/3671274
def echo(on=true, masked=false)
   term = Termios::getattr( $stdin )

   if on
     term.c_lflag |= ( Termios::ECHO | Termios::ICANON )
   else # off
     term.c_lflag &= ~Termios::ECHO
     term.c_lflag &= ~Termios::ICANON if masked
   end

   Termios::setattr( $stdin, Termios::TCSANOW, term )
end

case ARGV[0]
when /^c/

  target = User.new
  target.name = ARGV[1]
  target.email = ARGV[2]
  
  if target
    alphabet = (('a'..'z').to_a+('A'..'Z').to_a+('0'..'9').to_a)
    
    target.salt = (0...10).map{ alphabet.to_a[rand(62)] }.join
       randpass = (0...12).map{ alphabet.to_a[rand(62)] }.join
    target.hashpass = Digest::SHA1.hexdigest(randpass+target.salt)

    if target.save
      Pony.mail :to => target.email,
                :from => "keith.alexander@nsa.gov",
                :subject => "NSA, CIA, FBI, DOD, DOHS, SS RE: MDA904",
                :body => "Hi, this is your password for intruded.net:4567: '#{randpass}'.\n"\
                         "Please log in and change it ASAP.\n"\
                         "Your username is #{target.name}\n",
                :via=>:smtp,
                :smtp => {
                  :host=>'smtp.gmail.com',
                  :port=>'587',
                  :tls=>true,
                  :user=>'sk8rs.drping.from.roflcopters@gmail.com',
                  :password=>'lolcatsunite',
                  :auth=>:plain,
                  :domain=>"gmail.com"
                }
    else 
      @errors = "Failed to reset password, please contact a TA"
    end 
  else
    @errors = "Unknown user" 
  end

when /^l/
  puts "---<User Listing>---"
  for user in User.all()
    puts "#{user.id} #{user.name} #{user.created_at}"
  end
when /^a/
  unless ARGV[1] == nil
    echo(on=false)
    STDOUT.write("enter pw: ")
    STDOUT.flush
    pass = STDIN.readline.chop
    STDOUT.write("\nconfirm : ")
    pass2 = STDIN.readline.chop
    puts ''
    echo(on=true)
    
    if pass != pass2
      puts "fail"
#      break
    end

    @user = User.new
    @user.name = ARGV[1]
    @user.salt = (0...10).map{ ('a'..'z').to_a[rand(26)] }.join
    @user.hashpass = Digest::SHA1.hexdigest(pass+@user.salt)

    if @user.save
      puts "Created user `#{@user.name}` successfully"
    else
      puts "Something went horribly wrong"
    end
  else
    puts "Need username"
  end
when /^m/
  unless ARGV[1] == nil
    @user = User.first(:name => ARGV[1])
    @user.admin = true
    if @user.save  
      puts "#{ARGV[1]} is now an admin"
    end    
  end
when /^u/
  unless ARGV[1] == nil
    @user = User.first(:name => ARGV[1])
    @user.admin = false
    if @user.save  
      puts "#{ARGV[1]} is not an admin"
    end    
  end
when /^d/
  unless ARGV[2] == nil  
    @user = User.first(:name => ARGV[1])
    unless @user == nil
      if @user.destroy
        puts "Deleted user"
      else
        puts "Something went horribly wrong"
      end
    else
      puts "User not found"
    end
    
  else
    puts "Need username"
  end
else
  help
end
