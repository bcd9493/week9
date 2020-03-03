# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"  
require "sinatra/cookies"                                                             #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "bcrypt"                                                                      #
require "twilio-ruby"                                                                 #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

events_table = DB.from(:events)
rsvps_table = DB.from(:rsvps)
users_table = DB.from(:users)

get "/" do
    puts events_table.all
    @events = events_table.all.to_a
    view "events"
end

get "/events/:id" do
    @event = events_table.where(id: params[:id]).to_a[0]
    @rsvps = rsvps_table.where(event_id: @event[:id])
    @going_count = rsvps_table.where(event_id: @event[:id]).sum(:going)
    view "event"
end

get "/events/:id/rsvps/new" do
    @event = events_table.where(id: params[:id]).to_a[0]
    view "new_rsvp"
end

get "/events/:id/rsvps/create" do
    puts params
    @event = events_table.where(id: params[:id]).to_a[0]
    rsvps_table.insert(event_id: params["id"],
                        user_id: session["user_id"],
                        going: params["going"],
                        comments: params["comments"],)
    view "create_rsvp"
end

get "/users/new" do
    view "new_user"
end

get "/users/create" do
    puts params
    users_table.insert(name: params["name"],
                        email: params["email"],
                        password: BCrypt::Password.create(params["password"]),)
    view "create_user"
end

get "/logins/new" do
    view "new_login"
end

post "/logins/create" do
    puts params
    email_address = params["email"]
    password = params["password"]

    @user = users_table.where(email: email_address).to_a[0]

    if @user 
        if BCrypt::Password.new(@user[:password]) == password
            session["user_id"] = @user[:id]
            view "create_login"
        else
            view "create_login_failed"  
        end
    else
        view "create_login_failed"
    end

end

get "/logout" do
    view "logout"
end