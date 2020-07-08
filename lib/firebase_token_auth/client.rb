require 'json'
require 'openssl'
require 'jwt'

require 'firebase_token_auth/public_key_manager'
require 'firebase_token_auth/validator'
require 'firebase_token_auth/admin_client'

module FirebaseTokenAuth
  ALGORITHM = 'RS256'.freeze

  IdToken = Struct.new(:payload, :header)
  IdTokenResult = Struct.new(:uid, :id_token)

  class Client
    CUSTOM_TOKEN_AUD = 'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit'.freeze

    attr_accessor :configuration, :public_key_manager, :validator

    def initialize(configuration)
      @configuration = configuration
      @configuration.prepare
      @public_key_manager = PublicKeyManager.new
      @validator = Validator.new
    end

    def verify_id_token(id_token, options = {})
      raise if id_token.nil? || id_token.empty?

      public_key_id, decoded_jwt = validator.extract_kid(id_token)
      public_key_manager.refresh_publickeys!
      validator.validate(configuration.project_id, decoded_jwt)
      default_options = { algorithm: ALGORITHM, verify_iat: true, verify_expiration: true, exp_leeway: configuration.exp_leeway }
      jwt = JWT.decode(id_token, public_key_manager.public_keys[public_key_id].public_key, true, default_options.merge!(options))
      IdTokenResult.new(jwt[0]['sub'], IdToken.new(jwt[0], jwt[1]))
    end

    def create_custom_token(uid, additional_claims = nil)
      # TODO: implement Error
      raise unless configuration.configured_for_custom_token?

      now_seconds = Time.now.to_i
      payload = { iss: configuration.client_email,
                  sub: configuration.client_email,
                  aud: CUSTOM_TOKEN_AUD,
                  iat: now_seconds,
                  exp: now_seconds + (60 * 60),
                  uid: uid }
      payload.merge!({ claim: additional_claims }) if additional_claims
      JWT.encode(payload, configuration.private_key, ALGORITHM)
    end

    def user_search_by_email(email)
      admin_client.get_account_info({ email: [email] })&.users&.map(&:to_h)
    end

    def user_search_by_uid(uid)
      admin_client.get_account_info({ local_id: [uid] })&.users&.map(&:to_h)
    end

    private

      def admin_client
        @admin_client ||= FirebaseTokenAuth::AdminClient.new(configuration)
      end
  end
end
