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
require 'gapps_openid'

use Rack::Session::Cookie, :secret => 'supers3cr3t'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://localhost/harryqrcache.db")

class Setting 
include DataMapper::Resource
  property :id,           Serial
  property :name,         String, :required => true
  property :value,        String
end
DataMapper.finalize

use OmniAuth::Builder do
  provider :open_id,  :name => 'openid',
    :identifier => 'https://www.google.com/accounts/o8/id',
    :store => OpenID::Store::Filesystem.new('/tmp')
end

# Callback URL used when the authentication is done
post '/auth/openid/callback' do
  auth_details = request.env['omniauth.auth']
  session[:email] = auth_details.info['email']
  auth_details
# redirect '/auth/openid/welcome'
end

get '/foo' do
  "Hello #{session[:email]}<br>" +
    "Session: #{session}<br>" +
    "ENV: #{request.env}<br>"
end

get '/auth/openid/welcome' do
  if session[:email]
    redirect '/foo'
  else
    redirect '/auth/openid'
  end
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
  open_64 = cookies[:openval]
  open_s  = Base64.decode64(open_64)
  open    = DateTime.parse(open_s)
  close   = open.to_time + eval(ENV['WINDOW_CLOSE_DELAY'])

  now = DateTime.now.to_datetime
  @now_s = now.strftime('%H:%M:%S')

  if now.to_datetime < open.to_datetime
    @open_s = open.strftime('%H:%M:%S')
    slim :notyetdue
  elsif now.to_datetime > close.to_datetime
    @close_s = close.strftime('%H:%M:%S')
    slim :alreadygone
  else
    @coords = ENV['FINAL_TARGET_LATLON']
    slim :doorisopen
  end
end

post '/startcache' do
  now = DateTime.now.to_time
  open    = (now + eval(ENV['WINDOW_OPEN_DELAY'])).to_datetime
  cookies[:openval] = Base64.encode64(open.to_s)
  @coords = ENV['FINAL_TARGET_LATLON']
  slim :startresponse
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
p Nächstes Ziel:
  b =@coords

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

/ vim: set sw=2 ts=2 enc=utf8:
