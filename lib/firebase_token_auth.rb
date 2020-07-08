require 'firebase_token_auth/version'

require 'firebase_token_auth/configuration'
require 'firebase_token_auth/client'

require 'pry-byebug'

module FirebaseTokenAuth
  class Error < StandardError; end

  class << self
    def build
      @client = ::FirebaseTokenAuth::Client.new(configuration)
    end
    alias new build
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure(&block)
    yield(configuration(&block))
  end
end
