require 'openssl'
require 'net/http'
require 'exceptions'

module FirebaseTokenAuth
  class PublicKeyManager
    PUBLIC_KEY_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'.freeze
    attr_accessor :public_keys, :expire_time

    def initialize
      fetch_publickeys_hash
    end

    def refresh_publickeys!
      return unless expired?

      fetch_publickeys_hash
    end

    private

      def fetch_publickeys_hash
        res = exception_handler(Net::HTTP.get_response(URI(PUBLIC_KEY_URL)))
        @public_keys = JSON.parse(res.body).transform_values! { |v| OpenSSL::X509::Certificate.new(v) }
        @expire_time = cache_control_header_to_expire_time(res['Cache-Control'])
      end

      def expired?
        @expire_time.to_i > Time.now.to_i
      end

      def cache_control_header_to_expire_time(cache_control_header)
        Time.now.to_i + cache_control_header.match(/max-age=([0-9]*)/)[1].to_i
      end

      def exception_handler(response)
        error = STATUS_TO_EXCEPTION_MAPPING[response.code]
        raise error.new("Receieved an error response #{response.code} #{error.to_s.split('::').last}: #{response.body}", response) if error

        response
      end
  end
end
