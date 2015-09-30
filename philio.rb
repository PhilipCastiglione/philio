require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/reloader'
require 'twilio-ruby'

config_file 'config_or_whatever.yml'

account_sid = settings.twilio[:account_sid]
auth_token_totes_sekret = settings.twilio[:auth_token]

get '/' do
  "oh yeah baby"
end

