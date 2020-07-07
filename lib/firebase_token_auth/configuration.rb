module FirebaseTokenAuth
  class Configuration
    attr_accessor :project_id, :json_key_io, :admin_email, :admin_private_key, :private_key, :client_email, :exp_leeway

    def initialize
      @project_id = nil
      @exp_leeway = 60 * 60 * 24 * 7

      # if you want to create custom_token,
      # you need credentials which a) json_key_io or b) admin_email and admin_private_key

      # set file path or StringIO
      @json_key_io = nil

      # Or set these
      @admin_email = nil
      @admin_private_key = nil
    end
    alias :client_email :admin_email

    def prepare
      # TODO: implement error
      raise unless project_id
      return unless configured_for_custom_token?
      if json_key_io
        json_io = json_key_io.respond_to?(:read) ? json_key_io : File.open(json_key_io)
        parsed = JSON.parse(json_io.read)
        @private_key = OpenSSL::PKey::RSA.new(parsed['private_key'])
        @admin_email = parsed['client_email']
      else
        @private_key = OpenSSL::PKey::RSA.new(admin_private_key)
        @admin_email = admin_email
      end
    end

    def configured_for_custom_token?
      json_key_io || (admin_email && admin_private_key)
    end
  end
end

