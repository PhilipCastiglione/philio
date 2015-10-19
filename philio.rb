require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/reloader'
require 'twilio-ruby'
require 'tilt/erb'
require 'net/http'
require 'json'

# block for config file approach to secrets
#config_file 'config_or_whatever.yml'
#account_sid = settings.twilio[:account_sid]
#auth_token = settings.twilio[:auth_token]
#traction_user_id = settings.traction[:user_id]
#traction_endpoint_id = settings.traction[:endpoint_id]
#traction_password = settings.traction[:password]

# block for environment variables approach to secrets
account_sid = ENV['ACCOUNT_SID']
auth_token = ENV['AUTH_TOKEN']
traction_password = ENV['TRACTION_PASSWORD']
traction_user_id = ENV['USER_ID']
traction_endpoint_id = ENV['ENDPOINT_ID']

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
  Twilio::TwiML::Response.new do |r|
    r.Play "http://philioapp.herokuapp.com/welcome.mp3"
    r.Say "Welcome to Philio, the Twilio API test app."
    r.Redirect "http://philioapp.herokuapp.com/get_dob"
  end.text
end

post '/get_dob' do
  Twilio::TwiML::Response.new do |r|
    r.Say "Please enter your date of birth in days, months and years, followed by the hash key. For example, the third of April nineteen eighty five would be entered zero three, zero four, one nine eight five, hash."
    r.Gather action: "http://philioapp.herokuapp.com/validate_dob"
    r.Say "Your date of birth must be entered to continue."
    r.Redirect "http://philioapp.herokuapp.com/get_dob"
  end.text
end

post '/validate_dob' do
  dob = params[:Digits]

  day = dob.slice(0,2).to_i
  month = dob.slice(2,2).to_i
  year = dob.slice(4,4).to_i

  begin
    age = (Time.now - Time.new(year, month, day)) / 60 / 60 / 24 / 365
  rescue
    age = 'invalid'
  end

  Twilio::TwiML::Response.new do |r|
    if age == 'invalid'
      r.Say "Your date of birth did not pass validation."
      r.Redirect "http://philioapp.herokuapp.com/get_dob"
    elsif age < 18
      r.Say "Oh no! You must be 18 to claim free beer! Come back on your 18th birthday."
    else
      r.Say "That would make you #{age.to_i} years old. Getting on a bit there buddy. Is that correct?"
      r.Say "Press 1 to confirm or any other key to go back and try again."
      r.Gather action: "http://philioapp.herokuapp.com/confirm_dob", numDigits: "1"
      r.Say "We didn't receive any response."
      r.Redirect "http://philioapp.herokuapp.com/get_dob"
    end
  end.text
end

post '/confirm_dob' do
  confirm = params[:Digits]

  Twilio::TwiML::Response.new do |r|
    if confirm != "1"
      r.Redirect "http://philioapp.herokuapp.com/get_dob"
    else
      r.Say "To claim a delicious beer, we will send you a text message with instructions."
      r.Redirect "http://philioapp.herokuapp.com/get_mobile"
    end
  end.text
end
 
post '/get_mobile' do
  Twilio::TwiML::Response.new do |r|
    r.Say "Please enter your mobile phone number, followed by the hash key. Don't be shy, winky face!"
    r.Gather action: "http://philioapp.herokuapp.com/validate_mobile"
    r.Say "No number was recorded."
    r.Redirect "http://philioapp.herokuapp.com/get_mobile"
  end.text
end

post '/validate_mobile' do
  mobile_num = params[:Digits]
  spoken_num = mobile_num.split('').join(' ')

  Twilio::TwiML::Response.new do |r|
    if mobile_num.length != 10
      r.Say "We were expecting 10 digits for a mobile, but we received the number #{spoken_num}."
      r.Redirect "http://philioapp.herokuapp.com/get_mobile"
    elsif mobile_num[0] != "0"
      r.Say "We were expecting the first number to be a zero but we received the number #{spoken_num}. Don't worry about area code."
      r.Redirect "http://philioapp.herokuapp.com/get_mobile"
    else
      r.Say "You entered the number #{spoken_num}. Is that correct?"
      r.Say "Press 1 to confirm or any other key to go back and try again."
      r.Gather action: "http://philioapp.herokuapp.com/confirm_mobile/#{mobile_num}", numDigits: "1"
      r.Say "We didn't receive any response."
      r.Redirect "http://philioapp.herokuapp.com/get_mobile"
    end
  end.text
end

post '/confirm_mobile/:number' do
  confirm = params[:Digits]

  Twilio::TwiML::Response.new do |r|
    if confirm != "1"
      r.Redirect "http://philioapp.herokuapp.com/get_mobile"
    else
      r.Say "Let us just confirm your mobile number. This may take a few seconds."
      r.Redirect "http://philioapp.herokuapp.com/confirm_traction/#{params[:number]}"
    end
  end.text
end

post '/confirm_traction/:number' do
  retrieve_uri = URI.parse('http://int.api.tractionplatform.com/ext/RetrieveCustomer')
  add_uri = URI.parse('http://int.api.tractionplatform.com/ext/AddCustomer')
  data = {
    'MATCHKEY': 'M',
    'MATCHVALUE': params[:number],
    'PASSWORD': traction_password,
    'USERID': traction_user_id,
    "ENDPOINTID": traction_endpoint_id
  }

  retrieve_response = Net::HTTP.post_form(retrieve_uri, data)

  if retrieve_response['trac-result'] == '7'
    # make async;
    # add_response = Net::HTTP.post_form(add_uri, data)
    # start text message
  end

  Twilio::TwiML::Response.new do |r|
    if retrieve_response['trac-result'] == '7'
      r.Say "Ace, expect a text message soon. Enjoy your beer!"
    elsif retrieve_response['trac-result'] == '0'
      r.Say "You are have already signed up and are not eligble."
    else
      r.Say "Soz, #{retrieve_response['trac-error']}."
    end
  end.text
end

#is it possible to check that the user agent is the twilio server? this might manage the risk of arbitrary posts to signup mass users
