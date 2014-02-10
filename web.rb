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
    "startpage"
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
        coords = HTMLEntities.new.encode(ENV['TARGET_LATLON'])
        "Letzte Koordinaten: <b>#{coords}"
    end
end

get '/startcache' do
    now = DateTime.now.to_time
    open =  (now + eval(ENV['WINDOW_OPEN_DELAY'])).to_datetime
    open_s = open.to_s
    open_64 = Base64.encode64(open_s)
    cookies[:openval] = open_64
    "Now: #{now.to_s}<br>" +
    "Open: #{open.to_s} &rarr; #{open_64}<br>"
end
