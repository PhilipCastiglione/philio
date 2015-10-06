require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/reloader'
require 'twilio-ruby'
require 'tilt/erb'
require 'pry'

# block for config file approach to secrets
#config_file 'config_settings.yml'
#account_sid = settings.twilio[:account_sid]
#auth_token = settings.twilio[:auth_token]

# block for environment variables approach to secrets
account_sid = ENV['ACCOUNT_SID']
auth_token = ENV['AUTH_TOKEN']

get '/' do
  erb :index
end

get '/test' do
  @client = Twilio::REST::Client.new account_sid, auth_token
  @client.account.calls.create(:url => "https://philioapp.herokuapp.com/welcome",
                               :to   => "+61431838460",
                               :from => "+61282945949")
  "The test call is underway, using default number 0431838460."
end

get '/test/:number' do
  @client = Twilio::REST::Client.new account_sid, auth_token
  @client.account.calls.create(:url => "https://philioapp.herokuapp.com/welcome",
                               :to   => "+61" + params[:number],
                               :from => "+61282945949")
  "The test call is underway, using number 0#{params[:number]}."
end

get '/thing/:number' do
  "the number is +61" + params[:number]
end

post '/welcome' do
  response = Twilio::TwiML::Response.new do |r|
    r.Play "http://philioapp.herokuapp.com/welcome.mp3"
    r.Say "Welcome to Philio, the Twilio API test app."
    r.Redirect "http://philioapp.herokuapp.com/gather"
  end
  response.text
end

post '/gather' do
  response = Twilio::TwiML::Response.new do |r|
    r.Say "Please enter a number, followed by the hash key."
    r.Gather action: "http://philipapp.herokuapp.com/respond"
    r.Say "No number was recorded."
    r.Redirect "http://philioapp.herokuapp.com/gather"
  end
  p response
  response.text
end

post '/respond' do
  num = params[:Digits]

  p num

  response = Twilio::TwiML::Response.new do |r|
    r.Say "You entered the number #{num}. Goodbye"
  end
  response.text
end

