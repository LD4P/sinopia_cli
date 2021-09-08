# frozen_string_literal: true

require 'thor'
require 'faraday'

# Client for Sinopia API
class Client
  def self.connection(token: nil)
    Faraday.new(
      headers: {
        'Content-Type' => 'application/json'
      }.tap do |headers|
        headers['Authorization'] = "Bearer #{token}" if token
      end
    )
  end
end
