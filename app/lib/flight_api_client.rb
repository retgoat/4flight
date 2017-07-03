# encoding: utf-8
require 'faraday'

class FlightApiClient
  def initialize
    @url = "http://node.locomote.com"
  end

  def get_airport(city)
    do_request("/airports", {q: city})
  end

  def get_airlines
    do_request("/airlines", nil)
  end

  def search(flight_code, from, to, date)
    do_request("/flight_search/#{flight_code}", {to: to, from: from, date: date})
  end

  private

  def do_request(path, params)
    resp = conn = ::Faraday.new(url: @url) do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end.get("/code-task/#{path}", params)
    if resp.body
      JSON.parse(resp.body, symbolize_names: true)
    else
      []
    end
  # Actually we should raise another error here, but let it will be an empty response for now
  rescue JSON::ParserError
    []
  rescue Faraday::Error
    []
  end
end
