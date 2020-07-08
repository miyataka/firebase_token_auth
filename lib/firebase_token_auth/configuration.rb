require 'google/apis/identitytoolkit_v3'
require 'openssl'

module FirebaseTokenAuth
  class Configuration
    attr_accessor :project_id, :json_key_io, :exp_leeway, :private_key, :client_email, :scope, :auth

    def initialize
      @project_id = nil
      @exp_leeway = 60 * 60 * 24 * 7
      @scope = ['https://www.googleapis.com/auth/identitytoolkit']

      # if you want to create custom_token,
      # you need credentials which a) json_key_io or b) admin_email and admin_private_key

      # set file path or StringIO
      @json_key_io = nil

      # Or set these
      # ENV['GOOGLE_ACCOUNT_TYPE'] = 'service_account'
      # ENV['GOOGLE_CLIENT_ID'] = '000000000000000000000'
      # ENV['GOOGLE_CLIENT_EMAIL'] = 'xxxx@xxxx.iam.gserviceaccount.com'
      # ENV['GOOGLE_PRIVATE_KEY'] = '-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n'
    end

    def prepare
      # TODO: implement error
      raise unless project_id
      return unless configured_for_custom_token?

      @auth = if json_key_io
                io = json_key_io.respond_to?(:read) ? json_key_io : File.open(json_key_io)
                Google::Auth::ServiceAccountCredentials.make_creds(
                  json_key_io: io,
                  scope: scope
                )
              else
                # from ENV
                Google::Auth::ServiceAccountCredentials.make_creds(scope: scope)
              end

      if json_key_io
        json_io = json_key_io.respond_to?(:read) ? json_key_io : File.open(json_key_io)
        parsed = JSON.parse(json_io.read)
        @private_key = OpenSSL::PKey::RSA.new(parsed['private_key'])
        @client_email = parsed['client_email']
      else
        @private_key = OpenSSL::PKey::RSA.new(ENV['GOOGLE_PRIVATE_KEY'])
        @client_email = ENV['GOOGLE_CLIENT_EMAIL']
      end
    end

    def configured_for_custom_token?
      json_key_io || (ENV['GOOGLE_PRIVATE_KEY'] && ENV['GOOGLE_CLIENT_EMAIL'])
    end
  end
end
