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

post '/welcome' do
  response = Twilio::TwiML::Response.new do |r|
    r.Play "http://philioapp.herokuapp.com/welcome.mp3"
    r.Say "Welcome to Philio, the Twilio API test app."
    r.Redirect "http://philioapp.herokuapp.com/get_dob"
  end
  response.text
end

post '/get_dob' do
  response = Twilio::TwiML::Response.new do |r|
    r.Say "Please enter your date of birth. The third of April nineteen eighty five would be entered zero three, zero four, one nine eight five, followed by the hash key."
    r.Gather action: "http://philioapp.herokuapp.com/validate_dob"
    r.Say "Your date of birth must be entered to continue."
    r.Redirect "http://philioapp.herokuapp.com/get_dob"
  end
  response.text
end

post '/validate_dob' do
  dob = params[:Digits]
  day = dob.slice(0,2).to_i
  month = dob.slice(2,2).to_i
  year = dob.slice(4,4).to_i

  age = (Time.now - Time.new(year, month, day)) / 60 / 60 / 24 / 365

  response = Twilio::TwiML::Response.new do |r|
    if age < 18
      r.Say "Oh no! You must be 18 to claim free beer! Come back on your 18th birthday."
    else
      r.Say "That would make you #{age.to_i} years old. Getting on a bit there buddy. Is that correct?"
      r.Say "Press 1 to confirm or 0 to go back and enter again, followed by the hash key."
      r.Gather action: "http://philioapp.herokuapp.com/confirm_dob"
      r.Say "We didn't receive any response."
      r.Redirect "http://philioapp.herokuapp.com/get_dob"
    end
  end
  response.text
end

post '/confirm_dob' do
  confirm = params[:Digits]

  response = Twilio::TwiML::Response.new do |r|
    if confirm != "1"
      r.Redirect "http://philioapp.herokuapp.com/get_dob"
    else
      r.Say "To claim a delicious beer, we will send you a text message with instructions."
      r.Redirect "http://philioapp.herokuapp.com/get_mobile"
    end
  end
  response.text
end
 
post '/get_mobile' do
  response = Twilio::TwiML::Response.new do |r|
    r.Say "Please enter your mobile phone number, followed by the hash key. Don't be shy winky face!"
    r.Gather action: "http://philioapp.herokuapp.com/validate_mobile"
    r.Say "No number was recorded."
    r.Redirect "http://philioapp.herokuapp.com/get_mobile"
  end
  response.text
end

post '/validate_mobile' do
  mobile_num = params[:Digits]

  response = Twilio::TwiML::Response.new do |r|
    if mobile_num.length != 10
      r.Say "We were expecting 10 digits for a mobile, but we received the number #{mobile_num}."
      r.Redirect "http://philioapp.herokuapp.com/get_mobile"
    elsif mobile_num[0] != "0"
      r.Say "We were expecting the first number to be a zerom but we received the number #{mobile_num}. Don't worry about area code or anything."
      r.Redirect "http://philioapp.herokuapp.com/get_mobile"
    else
      r.Say "You entered the number #{mobile_num}. Is that correct?"
      r.Say "Press 1 to confirm or 0 to go back and enter again, followed by the hash key."
      r.Gather action: "http://philioapp.herokuapp.com/confirm_mobile"
      r.Say "We didn't receive any response."
      r.Redirect "http://philioapp.herokuapp.com/get_mobile"
    end
  end
  response.text
end

post '/confirm_mobile' do
  confirm = params[:Digits]

  response = Twilio::TwiML::Response.new do |r|
    if confirm != "1"
      r.Redirect "http://philioapp.herokuapp.com/get_mobile"
    else
      r.Say "Ace, expect a text message soon. Enjoy your beer!"
    end
  end

  #start an async job to send the call to traction if confirm == "1"
  response.text
end
