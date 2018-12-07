require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'open-uri'
require 'httparty'

FULL_OPACITY = 1.5

configure do
  enable :sessions
  set :session_secret, 'session_key' # hide
end

before do
  session[:history] ||= []
end

def google(form)
  #
  #
  
  results = HTTParty.get("https://www.googleapis.com/customsearch/v1?q=#{form}&cx=#{cx_code}&num=10&key=#{api_key}&searchType=image")
  results['items'].map { |item| item['link'] }
end

def valid_input?(form_name)
  return false unless form_name.match(/\A[a-z ]*[a-z0-9]+[a-z ]*\z/i)
  return false if session[:form_name] == cleaned(form_name)
  true
end

def add_to_history(form_name)
  unless session[:history].include? form_name
    session[:history] << form_name
  end

  while session[:history].size > 20
    session[:history].shift
  end
end

def cleaned(form_name)
  form_name = form_name.gsub(/ +/, ' ').downcase.strip
  URI.encode(form_name)
end

get '/' do
  redirect '/chair'
end

get '/about' do
  form_name = 'sailboat'
  erb :about
end

get '/:form_name' do
  form_name = params[:form_name]

  session[:form_name] = form_name
  session[:images] = google(session[:form_name])
  session[:opacity] = FULL_OPACITY / session[:images].size

  erb :index
end

post '/consider' do
  if valid_input?(params[:form_name])
    form_name = cleaned(params[:form_name])
    add_to_history(form_name)
    redirect "/#{form_name}"
  else
    redirect "/#{session[:form_name]}"
  end
end