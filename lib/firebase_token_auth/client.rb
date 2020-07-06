require 'public_keys'
require 'validator'

module FirebaseTokenAuth
  class Client
    attr_accessor :configuration, :public_keys, :expire_time, :private_key, :client_email

    CUSTOM_TOKEN_AUD = 'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit'.freeze
    ALGORITHM = 'RS256'.freeze

    def_delegators @configuration, :project_id, :private_key, :client_email
    def_delegators @pubkey_manager, :public_keys, :refresh_publickeys!, :extract_kid
    def_delegators @validator, :validate, :extract_kid

    def initialize(configuration)
      @configuration = configuration
      configuration.prepare
      @pubkey_manager = PublicKeys.new
      @validator = Validator.new
    end

    def verify_id_token(id_token)
      refresh_publickeys!
      public_key_id, decoded_jwt = extract_kid(id_token)
      validate(decoded_jwt)
      # FIXME: option
      JWT.decode(id_token, public_keys[public_key_id])
    end

    def create_custom_token(uid, additional_claims = nil)
      # TODO: implement Error
      raise unless configured_for_custom_token?
      now_seconds = Time.now.to_i
      payload = { iss: client_email,
                  sub: client_email,
                  aud: CUSTOM_TOKEN_AUD,
                  iat: now_seconds,
                  exp: now_seconds + (60 * 60),
                  uid: uid }
      payload.merge!({ claim: additional_claims }) if additional_claims
      JWT.encode(payload, private_key, ALGORITHM)
    end
  end
end
