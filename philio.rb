require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/reloader'
require 'twilio-ruby'
require 'pry'

#config_file 'config_or_whatever.yml'

#account_sid = settings.twilio[:account_sid]
#auth_token_totes_sekret = settings.twilio[:auth_token]
account_sid = ENV['ACCOUNT_SID']
auth_token_totes_sekret = ENV['AUTH_TOKEN']

get '/' do
  "oh yeah baby"
end

get '/client' do
  @client = Twilio::REST::Client.new account_sid, auth_token_totes_sekret
  @client
end

get '/testcall/:number' do
  @client = Twilio::REST::Client.new account_sid, auth_token_totes_sekret
  @client.account.calls.create(:url => "https://philioapp.herokuapp.com/testcontent",
                               :to   => "+61" + params[:number],
                               :from => "+61282945949")
  'you are on a page'
end

get '/thing/:number' do
  "the number is +61" + params[:number]
end

post '/testcontent' do
  response = Twilio::TwiML::Response.new do |r|
    r.Say "This is a Twilio public service announcement. Bunts is about to get his ass pounded in wall ball."
  end
  response.text
end

get '/testcontent' do
  response = Twilio::TwiML::Response.new do |r|
    r.Say "This is a Twilio public service announcement. Bunts is about to get his ass pounded in wall ball."
  end
  response.text
end
