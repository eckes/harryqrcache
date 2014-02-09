require 'sinatra'
require "sinatra/cookies"
require "base64"

get '/' do
  "openval: #{cookies[:openval]}" +
  "closeval: #{cookies[:closeval]}"
end

get '/get' do
    "open: #{cookies[:window_open]}"
    "close: #{cookies[:window_close]}"
end

get '/set' do
    now = DateTime.now.to_time
    open =  now + 1 * 60 * 60 # 1 hour in seconds
    close = open + 10 * 60    # 10 minutes in seconds
    open_s = open.to_s
    close_s = (open + 10 * 60).to_s
    open_64 = Base64.encode64(open_s)
    close_64 = Base64.encode64(close_s)
    "Now: #{now.to_s}<br>" +
    "Open: #{open.to_s} &rarr; #{open_64}<br>" +
    "Close: #{close.to_s} &rarr; #{close_64}"
    cookies[:openval] = open_64
    cookies[:closeval] = close_64
    redirect to('/')
end
