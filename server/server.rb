require 'sinatra'
require 'haml'
require 'sinatra/reloader'
require_relative 'grbl/grbl'
require_relative 'sensors/hcsro4'
require_relative 'sensors/mpu6050'
require_relative 'os'

configure do

  # set :public_folder, '/var/www'

  set :partisanink, GRBL.new
  set :head, GRBL.new
  set :rotation, MPU6050.new('/home/pi/wiringPi/wiringPi/libwiringPi.so.2.25')
  set :distance, HCSRO4.new('/home/pi/wiringPi/wiringPi/libwiringPi.so.2.25')
end

get '/' do
  haml :index
end

get '/status' do

end

get '/file' do

end

get '/settings' do

end

get '/sensors' do
  response['Access-Control-Allow-Origin'] = '*'
  settings.rotation.measure.to_s + ' ' + settings.distance.measure(17, 27).to_s
end

get '/move' do

end