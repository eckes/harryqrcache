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

# ==========================================================================================================================
# === Database Setup =======================================================================================================
# ==========================================================================================================================
DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://#{ENV['DB_USER']}:#{ENV['DB_PASSWORD']}@localhost/harryqrcache.db")
class Setting 
include DataMapper::Resource
  property :id,           Serial
  property :name,         String, :required => true
  property :value,        String
  property :description,  String
end
DataMapper.finalize

# ==========================================================================================================================
# === Authentication with OpenID ===========================================================================================
# ==========================================================================================================================
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

# ==========================================================================================================================
# === Main Logic: Starting, Ending the cache ===============================================================================
# ==========================================================================================================================
get '/' do
  slim :start
end

get '/startcache' do
  redirect to '/'
end

get '/endcache' do
  window_close_delay = eval(ENV['WINDOW_CLOSE_DELAY'] || Setting.first(:name => "WindowCloseDelay").value)
  final_target_latlon= ENV['FINAL_TARGET_LATLON']|| Setting.first(:name => "FinalTargetLatLon").value
  unless cookies && cookies[:openval]
    halt 412, '<a href="/">No cookie found, start again!</a>'
  end
  open_64 = cookies[:openval]
  open_s  = Base64.decode64(open_64)
  open    = DateTime.parse(open_s)
  close   = open.to_time + window_close_delay

  now = DateTime.now.to_datetime

  @now_s    = now.strftime('%H:%M:%S')
  @open_s   = open.strftime('%H:%M:%S')
  @close_s  = close.strftime('%H:%M:%S')
  @coords   = final_target_latlon

  if now.to_datetime < open.to_datetime
    slim :notyetdue
  elsif now.to_datetime > close.to_datetime
    slim :alreadygone
  else
    slim :doorisopen
  end
end

post '/startcache' do
  window_open_delay  = eval(ENV['WINDOW_OPEN_DELAY']  || Setting.first(:name => "WindowOpenDelay").value)
  now = DateTime.now.to_time
  open    = (now + window_open_delay).to_datetime
  cookies[:openval] = Base64.encode64(open.to_s)
  redirect '/cachestarted'
end

get '/cachestarted' do
  next_target_latlon = ENV['NEXT_TARGET_LATLON'] || Setting.first(:name => "NextTargetLatLon").value
  slim :startfailed unless cookies && cookies[:openval]
  redirect '/startcache' unless defined? next_target_latlon
  @coords = next_target_latlon
  slim :startresponse
end

# ==========================================================================================================================
# === PRIVATE URLS: Manage settings ========================================================================================
# ==========================================================================================================================
before '/private/*' do
  admins = (ENV['ADMINS'] || Setting.first(:name => "Admins").value)
  unless session && session[:email] && (admins.include? session[:email])
    halt 401, '<a href="/auth/openid">authentication required</a>'
  end
  @showtopbar = true
end

get '/private/settings' do
  @user_name = (session[:email] == 'meliundeckes@gmail.com' && 'Eckes') || 'Harry'
  @settings = Setting.all
  slim :showsettings
end

post '/private/settings' do
  params.each do |key, value|
    Setting.get(key).update(:value => value)
  end
  redirect '/private/settings'
end

get '/private/addsetting' do
  slim :addsetting
end

get '/private/alreadygone' do
  slim :alreadygone
end

post '/private/addsetting' do
  Setting.create( name: params['setting_name'], value: params['setting_value'], description: params['setting_description'] )
  redirect '/private/settings'
end

__END__

# ==========================================================================================================================
# === Web Page Templates ===================================================================================================
# ==========================================================================================================================

@@ layout
doctype 5
html
  head
    meta charset="utf-8"
    css:
      .topbar {
        padding-top: 5px;
        padding-bottom: 5px;
        font-weight: bold;
        text-align: center;
        font-family: monospace;
        background-color: #A4A4A4;}

      css.topbar {
        width: 100%;
        }

      ul.topbar li{
        display: inline;
        list-style-type: none;
        padding-left: 10px;
        padding-right: 10px; }
  body
    div.topbar
      ul.topbar
        li
          a href='https://github.com/eckes/harryqrcache'
            img src='/images/GitHub-Mark-32px.png' height='16px' width='16px' title='Fork me on GitHub'
        - if @showtopbar
          li
            a href='/private/addsetting' Add a setting
          li
            a href='/private/settings' Show settings
          li 
            a href='/' Start Page
  == yield

@@ start
h1 Startseite

h2 Herzlich willkommen zu Nerds, hurry up!

p Bei Betätigung des unteren START Buttons bekommt Ihr die Koordinaten für die 2. Stage.

h2 Problem!

p Zeitgleich beginnt ein Timer zu laufen. Ihr habt ab Drücken des START-Buttons 2 Stunden Zeit, um die vorletzte Station zu erreichen (Zeitfenster 90&ndash;120 Minuten).  Dort erhaltet Ihr bei zeitgerechtem Erscheinen die Koordinaten fürs Final.

p Solltet Ihr die Zeit überschreiten... Gehe zurück zu Los, gehen Sie direkt dorthin!

p Viel Spaß und... 

h2 Hurry up!
form method="POST" action="startcache"
  input.button type="submit" value="STARTEN"

@@ startfailed
h1.error Start fehlgeschlagen
p Leider ist irgend etwas schief gegangen. Bitte
a href="/" nochmal probieren
p Cookies müssen aktiviert sein!

@@ startresponse
h1 Der Timer wurde gestartet
h2 Nächstes Ziel:
h3 =@coords

@@ notyetdue
h1 Tor noch nicht offen
ul
  li Momentane Zeit: #{@now_s}
  li Tor öffnet sich um #{@open_s}
a href='/endcache' Aktualisieren

@@ alreadygone
h1 Tor schon wieder geschlossen
ul
  li Momentane Zeit: #{@now_s}
  li Tor wurde geschlossen um #{@close_s}
p Sorry, Zeit nicht geschafft. Bitte zurück zum Start/Stage 1!
h2 ODER (Backup)
ul
  li N 50 06. Geburtsjahr des Preußen - BWW beider nach NNW zeigenden Schilder - 1218
  li E 11 36. BWW beider nach W zeigenden Schilder + 250

@@ doorisopen
h1 Glückwunsch!
p Ihr habt es innerhalb der geforderten Zeit geschafft! Durchatmen!
h2 Das Final findet Ihr bei
h3 =@coords
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


/ vim: set sw=2 ts=2 enc=utf8:
