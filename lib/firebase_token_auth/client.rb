require 'public_keys'
require 'validator'

module FirebaseTokenAuth
  ALGORITHM = 'RS256'.freeze

  IdToken = Struct.new(:payload, :header)
  IdTokenResult = Struct.new(:uid, :id_token)

  class Client
    attr_accessor :configuration, :validator, :pubkey_manager

    CUSTOM_TOKEN_AUD = 'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit'.freeze

    def_delegators @configuration, :project_id, :private_key, :client_email, :exp_leeway
    def_delegators @pubkey_manager, :public_keys, :refresh_publickeys!, :extract_kid
    def_delegators @validator, :validate

    def initialize(configuration)
      @configuration = configuration
      configuration.prepare
      @pubkey_manager = PublicKeys.new
      @validator = Validator.new
    end

    def verify_id_token(id_token, options = {})
      default_options = { verify_iat: true, verify_expiration: true, exp_leeway: exp_leeway }
      raise if id_token.nil? || id_token.empty?
      public_key_id, decoded_jwt = extract_kid(id_token)
      refresh_publickeys!
      validate(project_id, decoded_jwt)
      jwt = JWT.decode(id_token, public_keys[public_key_id], true, default_options.merge!(options))
      IdTokenResult.new(uid: jwt[0]['sub'],
                        id_token: IdToken.new(payload: jwt[0], header: jwt[1]))
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
