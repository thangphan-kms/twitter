# frozen_string_literal: true

require 'jwt'
require 'net/http'

class Auth0Client
  Error = Struct.new(:message, :status)
  Response = Struct.new(:decoded_token, :error)

  def self.domain_url
    "https://#{Rails.configuration.auth0.domain}"
  end

  def self.decode_token(token, jwks_hash)
    JWT.decode(token, nil, true, {
      algorithm: 'RS256',
      iss: domain_url,
      verify_iss: true,
      aud: Rails.configuration.auth0.audience.to_s,
      verify_aud: true,
      jwks: { keys: jwks_hash[:keys] }
    })
  end

  def self.fetch_jwks
    jwks_uri = URI("#{domain_url}.well-known/jwks.json")
    Net::HTTP.get_response jwks_uri
  end

  def self.generate_token
    # binding.pry
    url = URI("#{domain_url}/oauth/token")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(url)
    request['content-type'] = 'application/json'
    request.body = {
      client_id: ENV['AUTH0_CLIENT_ID'],
      client_secret: ENV['AUTH0_CLIENT_SECRET'],
      audience: ENV['AUTH0_AUDIENCE'],
      grant_type: 'client_credentials'
    }.to_json

    response = http.request(request)
    JSON.parse(response.body)['access_token']
  end

  def self.validate_token(token)
    jwks_response = fetch_jwks
    unless jwks_response.is_a? Net::HTTPSuccess
      error = Error.new(message: 'Unable to verify credentials', status: :internal_server_error)
      return Response.new(nil, error)
    end

    jwks_hash = JSON.parse(jwks_response.body).deep_symbolize_keys
    decoded_token = decode_token(token, jwks_hash)
    Response.new(decoded_token, nil)
  rescue JWT::VerificationError, JWT::DecodeError => e
    error = Error.new('Bad credentials', :unauthorized)
    Response.new(nil, error)
  end
end
