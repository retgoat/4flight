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
    erb :index
  end

  post '/search' do
    content_type :json
    if params["oneway"] == "true"
      # JSON.parse(File.read("stub.json")).to_json
      search_one_way
    else
      # JSON.parse(File.read("stub_both.json")).to_json
      search_both_ways if Date.parse(params[:departing]) > Date.today
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
    return empty_response unless date_valid?
    validated = ParamsValidator.new(params).validate_one_way_search_params
    if validated[:success]
      prms = validated[:params]
      airlines = client.get_airlines
      results = common_search(prms[:from], prms[:to], prms[:departing], airlines)
      if results
        {success: true, data: results, header: one_way_header}.to_json
      else
        {success: false, errors: {"Flights" => "not found"}}.to_json
      end
    else
      {success: false, errors: validated[:errors]}.to_json
    end
  end

  def search_both_ways
    return empty_response unless date_valid?
    validated = ParamsValidator.new(params).validate_both_ways_search_params
    if validated[:success]
      prms = validated[:params]
      airlines = client.get_airlines
      to_flights = common_search(prms[:from], prms[:to], prms[:departing], airlines)
      from_flights = common_search(prms[:to], prms[:from], prms[:returning], airlines)
      if to_flights && from_flights
        {success: true, data_to: to_flights, data_from: from_flights, header: both_ways_header }.to_json
      else
        {success: false, errors: "No flights found"}.to_json
      end
    else
      {success: false, errors: validated[:errors]}.to_json
    end
  end

  def date_valid?
    Date.parse(params[:departing]) > Date.today
  end

  def empty_response
    if params[:oneway] == "true"
      departing_results = get_dates(params[:departing]).map { |date| {"#{date}" =>[]}}
      {success: true, data: departing_results, header: one_way_header}.to_json
    else
      departing_results = get_dates(params[:departing]).map { |date| {"#{date}" =>[]}}
      returning_results = get_dates(params[:returning]).map { |date| {"#{date}" =>[]}}
      {success: true, data_to: departing_results, data_from: returning_results, header: both_ways_header }.to_json
    end
  end

  def one_way_header
    {departing: {to: params[:to], from: params[:from]}}
  end

  def both_ways_header
    {departing: {to: params[:to], from: params[:from]},
     returning: {to: params[:from], from: params[:to]}}
  end

  def common_search(from, to, date, airlines)
    dates = get_dates(date)
    # search for all available flights for all dates and all airlines
    airlines.flat_map do |airline|
      dates.map do |date|
        {"#{date}" => client.search(airline[:code], from, to, date)}
      end
    end
  end

  def get_dates(date)
    parsed_date = Date.parse(date)
    # returns an array of calculated 2 days after and before given date
    # pushes initial date into created array and sort it
    [2, 1].flat_map do |period|
      %i(+ -).flat_map do |sign|
        parsed_date.send(sign, period).to_s
      end
    end.push(parsed_date.to_s).sort!
  end

  def client
    @client ||= FlightApiClient.new
  end
end
