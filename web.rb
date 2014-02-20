# encoding: utf-8
require "base64"

require 'sinatra'
require "sinatra/cookies"
require "htmlentities"
require "data_mapper"

require "slim"

require 'omniauth-openid'
require 'openid'
require 'openid/store/filesystem'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://#{ENV['DB_USER']}:#{ENV['DB_PASSWORD']}@localhost/harryqrcache.db")
class Setting 
include DataMapper::Resource
  property :id,           Serial
  property :name,         String, :required => true
  property :value,        String
  property :description,  String
end
DataMapper.finalize


use Rack::Session::Cookie, :secret => 'supers3cr3t'

use OmniAuth::Builder do
  provider :open_id,  :name => 'openid',
    :identifier => 'https://www.google.com/accounts/o8/id',
    :store => OpenID::Store::Filesystem.new('/tmp')
end

# Callback URL used when the authentication is done
post '/auth/openid/callback' do
  auth_details = request.env['omniauth.auth']
  session[:email] = auth_details.info['email']
  redirect '/private/settings'
end

get '/auth/failure' do
  params[:message]
  # do whatever you want here.
end

OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

get '/' do
  slim :start
end

get '/startcache' do
  redirect to '/'
end

get '/endcache' do
  WINDOW_CLOSE_DELAY = eval(ENV['WINDOW_CLOSE_DELAY'] || Setting.first(:name => "WindowCloseDelay").value)
  FINAL_TARGET_LATLON= ENV['FINAL_TARGET_LATLON']|| Setting.first(:name => "FinalTargetLatLon").value
  open_64 = cookies[:openval]
  open_s  = Base64.decode64(open_64)
  open    = DateTime.parse(open_s)
  close   = open.to_time + WINDOW_CLOSE_DELAY

  now = DateTime.now.to_datetime
  @now_s = now.strftime('%H:%M:%S')

  @open_s = open.strftime('%H:%M:%S')
  @close_s = close.strftime('%H:%M:%S')
  @coords = FINAL_TARGET_LATLON

  if now.to_datetime < open.to_datetime
    slim :notyetdue
  elsif now.to_datetime > close.to_datetime
    slim :alreadygone
  else
    slim :doorisopen
  end
end

post '/startcache' do
  WINDOW_OPEN_DELAY  = eval(ENV['WINDOW_OPEN_DELAY']  || Setting.first(:name => "WindowOpenDelay").value)
  NEXT_TARGET_LATLON = ENV['NEXT_TARGET_LATLON'] || Setting.first(:name => "NextTargetLatLon").value
  now = DateTime.now.to_time
  open    = (now + WINDOW_OPEN_DELAY).to_datetime
  cookies[:openval] = Base64.encode64(open.to_s)
  @coords = NEXT_TARGET_LATLON
  slim :startresponse
end

get '/private/settings' do
  ADMINS             = ENV['ADMINS']             || Setting.first(:name => "Admins").value
  unless session && session[:email] && (ADMINS.include? session[:email])
    halt 401, '<a href="/auth/openid">authentication required</a>'
  end
  @user_name = (session[:email] == 'meliundeckes@gmail.com' && 'Eckes') || 'Harry'
  @settings = Setting.all
  slim :showsettings
end

post '/private/settings' do
  ADMINS             = ENV['ADMINS']             || Setting.first(:name => "Admins").value
  unless session && session[:email] && (ADMINS.include? session[:email])
    halt 401, '<a href="/auth/openid">authentication required</a>'
  end
  params.each do |key, value|
    Setting.get(key).update(:value => value)
  end
  redirect '/private/settings'
end

get '/private/addsetting' do
  ADMINS             = ENV['ADMINS']             || Setting.first(:name => "Admins").value
  unless session && session[:email] && (ADMINS.include? session[:email])
    halt 401, '<a href="/auth/openid">authentication required</a>'
  end
  slim :addsetting
end

post '/private/addsetting' do
  ADMINS             = ENV['ADMINS']             || Setting.first(:name => "Admins").value
  unless session && session[:email] && (ADMINS.include? session[:email])
    halt 401, '<a href="/auth/openid">authentication required</a>'
  end
  Setting.create( name: params['setting_name'], value: params['setting_value'], description: params['setting_description'] )
  redirect '/private/settings'
end

__END__

@@ layout
doctype html
html
head
meta charset="utf-8"
body
== yield

@@ start
h1 Startseite
ul
  li nach Klicken auf STARTEN startet ein Timer
  li vor Ablauf dieses Timers müssen drei Ziele erreicht werden
  li am dritten Ziel bekommt man die Koordinaten für den tollen Endpunkt
  li wenn man zu früh am dritten Ziel ist, muss man warten (d.h. das Tor zum Endpunkt ist noch zu)
  li wenn man zu spät am dritten Ziel ist, kriegt man die tollen Endkoordinaten nicht (d.h. das Tor zum Endpunkt ist schon wieder zu)
h2 Alles Klar?
form method="POST" action="startcache"
  input.button type="submit" value="STARTEN"

@@ startresponse
h1 Der Timer wurde gestartet
h2 Nächstes Ziel:
h3 =@coords

@@ notyetdue
h1 Tor noch nicht offen
ul
  li Momentane Zeit: #{@now_s}
  li Tor öffnet sich um #{@open_s}

@@ alreadygone
h1 Tor schon wieder geschlossen
ul
  li Momentane Zeit: #{@now_s}
  li Tor wurde geschlossen um #{@close_s}
p Damit gehts leider nicht zum fantastischen letzten Ziel

@@ doorisopen
h1 Letzte Koordinaten
h2 =@coords
p Diese Information verschwindet um #{@close_s}

@@ showsettings
h1 Hi #{@user_name}, hier die Einstellungen
form action="/private/settings" method="POST"
  table
    - @settings.each do |setting|
      tr
        td
          label for="#{setting.id}" #{setting.name}
        td
          input type="text" name="#{setting.id}" value="#{setting.value}"
        td
          label #{setting.description}
  input.button type="submit" value="Update Settings"
hr
a href='/private/addsetting' Add Setting

@@addsetting
h1 Add setting
form action="/private/addsetting" method="POST"
  table
    tr
      td
        label for="setting_name" Setting Name
      td
        input id="setting_name" type="text" name="setting_name" value=""
    tr
      td
        label for="setting_value" Setting Value
      td
        input id="setting_value" type="text" name="setting_value" value=""
    tr
      td
        label for="setting_description" Setting Description
      td
        input id="setting_description" type="text" name="setting_description" value=""
  input.button type="submit" value="Add Setting"

@@ listsettings
h1 Settings
table
  - @params.each do |param|
    tr
      td
        "#{param.name}"
      td
        "#{param.value}"

/ vim: set sw=2 ts=2 enc=utf8:
