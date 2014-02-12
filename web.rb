# encoding: utf-8
require "base64"

require 'sinatra'
require "sinatra/cookies"
require "htmlentities"

require "slim"

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
