module FirebaseTokenAuth
  class Validator
    ISSUER_BASE_URL = 'https://securetoken.google.com/'.freeze

    def validate(project_id, decoded_jwt)
      # ref. https://github.com/firebase/firebase-admin-node/blob/488f9318350c6b46af2e93b99907b9a02f170029/src/auth/token-verifier.ts
      payload = decoded_jwt[0]
      header = decoded_jwt[1]
      issuer = ISSUER_BASE_URL + project_id
      raise ValidationError, 'Firebase ID token has no "kid" claim.' unless header['kid']
      raise ValidationError, "Firebase ID token has incorrect algorithm. Expected \"#{ALGORITHM}\" but got \"#{header['alg']}\"." unless header['alg'] == ALGORITHM
      raise ValidationError, "Firebase ID token has incorrect \"aud\" (audience) claim. Expected \"#{project_id}\" but got \"#{payload['aud']}\"." unless payload['aud'] == project_id
      raise ValidationError, "Firebase ID token has \"iss\" (issuer) claim. Expected \"#{issuer}\" but got \"#{payload['iss']}\"." unless payload['iss'] == issuer
      raise ValidationError, 'Firebase ID token has no "sub" (subject) claim.' unless payload['sub'].is_a?(String)
      raise ValidationError, 'Firebase ID token has an empty string "sub" (subject) claim.' if payload['sub'].empty?
      raise ValidationError, 'Firebase ID token has "sub" (subject) claim longer than 128 characters.' if payload['sub'].size > 128
      raise ValidationError, 'Firebase ID token has expired.' if expired?(payload['exp'])
    end

    def extract_kid(id_token)
      decoded = JWT.decode(id_token, nil, false, algorithm: ALGORITHM)
      [decoded[1]['kid'], decoded]
    end

    def expired?(exp)
      exp.to_i <= Time.now.to_i
    end
  end
end
