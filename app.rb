# encoding: utf-8
require 'sinatra'
require 'json'
require_relative 'config/config.rb'

class App < Sinatra::Base
  configure do
    set :root, File.dirname(__FILE__)
    set :views, 'app/views'
  end

  configure :development, :test do
    require 'pry'
  end

  # Load all subdirectories in app/
  Dir.glob('./app/**/*.rb').each { |file| require file }

  # routes

  get '/' do
    @airlines = FlightApiClient.new.get_airlines
    erb :index
  end

  post '/search' do
    content_type :json
    # binding.pry
    if params["oneway"] == "true"
      JSON.parse(File.read("stub.json")).to_json
      # search_one_way
    else
      JSON.parse(File.read("stub_both.json")).to_json
      # search_both_ways
    end
  end

  get '/airport' do
    content_type :json
    @airports = client.get_airport(params[:query]).map do |a|
      {id: a[:airportCode], label: "#{a[:airportName]} #{a[:cityName]}, #{a[:countryName]}"}
    end.to_json
  end

  private

  def search_one_way
    validated = ParamsValidator.new(params).validate_one_way_search_params
    if validated[:success]
      prms = validated[:params]
      airlines = client.get_airlines
      results = common_search(prms[:from], prms[:to], prms[:departing], airlines)
      if results
        {success: true, data: results}.to_json
      else
        {success: false, errors: "No flights found"}.to_json
      end
    else
      {success: false, errors: validated[:errors]}.to_json
    end
  end

  def search_both_ways
    validated = ParamsValidator.new(params).validate_both_ways_search_params
    if validated[:success]
      prms = validated[:params]
      airlines = client.get_airlines
      to_flights = common_search(prms[:from], prms[:to], prms[:departing], airlines)
      from_flights = common_search(prms[:to], prms[:from], prms[:returning], airlines)
      if to_flights && from_flights
        {success: true, data_to: to_flights, data_from: from_flights}.to_json
      else
        {success: false, errors: "No flights found"}.to_json
      end
    else
      {success: false, errors: validated[:errors]}.to_json
    end
  end

  def common_search(from, to, date, airlines)
    airlines.flat_map do |airline|
      client.search(airline[:code], from, to, date)
    end
  end

  def client
    @client ||= FlightApiClient.new
  end
end
