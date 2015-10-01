require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/reloader'
require 'twilio-ruby'
require 'pry'
require 'nokogiri'

config_file 'config_or_whatever.yml'

account_sid = settings.twilio[:account_sid]
auth_token_totes_sekret = settings.twilio[:auth_token]


get '/' do
  "oh yeah baby"
end

get '/client' do
  @client = Twilio::REST::Client.new account_sid, auth_token_totes_sekret
  @client
end

get '/testcall' do
  @client = Twilio::REST::Client.new account_sid, auth_token_totes_sekret
  @client.account.calls.create(:url => "http://demo.twilio.com/docs/voice.xml",
                               :to   => "+61431838460",
                               :from => "+61282945949")
  "oh hi there #{params[:number]}"
end

post '/testcontent' do
  Nokogiri::XML::Builder.new do |xml|
    xml.Response {
      xml.Say "Some words"
    }
  end
end

