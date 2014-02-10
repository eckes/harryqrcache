# encoding: utf-8
require 'sinatra'
require "sinatra/cookies"
require "base64"
require "htmlentities"

class Numeric
  def duration
    secs  = self.to_int
    mins  = secs / 60
    hours = mins / 60
    days  = hours / 24

    if days > 0
      "#{days} days and #{hours % 24} hours"
    elsif hours > 0
      "#{hours} hours and #{mins % 60} minutes"
    elsif mins > 0
      "#{mins} minutes and #{secs % 60} seconds"
    elsif secs >= 0
      "#{secs} seconds"
    end
  end
end

get '/' do
    erb :start
end

get '/startcache' do
    redirect to '/'
end

get '/endcache' do
    open_64 = cookies[:openval]
    open_s = Base64.decode64(open_64)
    open = DateTime.parse(open_s)
    close = open.to_time + eval(ENV['WINDOW_CLOSE_DELAY'])

    now = DateTime.now.to_datetime
    now_s = now.strftime('%H:%M:%S')

    if now.to_datetime < open.to_datetime
        open_s = open.strftime('%H:%M:%S')
        "not yet due: now it's #{now_s}, window will open at #{open_s}"
    elsif now.to_datetime > close.to_datetime
        close_s = close.strftime('%H:%M:%S')
        "already expired: now it's #{now_s}, window closed at #{close_s}"
    else
        coords = HTMLEntities.new.encode(ENV['FINAL_TARGET_LATLON'])
        "Letzte Koordinaten: <b>#{coords}"
    end
end

post '/startcache' do
    now = DateTime.now.to_time
    open =  (now + eval(ENV['WINDOW_OPEN_DELAY'])).to_datetime
    open_s = open.to_s
    open_64 = Base64.encode64(open_s)
    cookies[:openval] = open_64
    coords = HTMLEntities.new.encode("Next Target: #{ENV['FINAL_TARGET_LATLON']}")
    "Der Timer wurde gestartet<br>" +
    "#{coords}"
end

__END__
@@ layout
<html>
    <head>
        <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
        </head>
  <body>
   <%= yield %>
  </body>
</html>

@@ start
<H1>Startseite</H1>
<ul>
    <li>nach Klicken auf STARTEN startet ein Timer</li>
    <li>vor Ablauf dieses Timers müssen drei Ziele erreicht werden</li>
    <li>am dritten Ziel bekommt man die Koordinaten für den tollen Endpunkt</li>
    <li>wenn man zu früh am dritten Ziel ist, muss man warten (d.h. das Tor zum Endpunkt ist noch zu)</li>
    <li>wenn man zu spät am dritten Ziel ist, kriegt man die tollen Endkoordinaten nicht (d.h. das Tor zum Endpunkt ist schon wieder zu)</li>
</ul>
<H2>Alles Klar?</H2>
<form method="POST" action="startcache">
    <button type="submit" value="start">STARTEN</button>
</form>

