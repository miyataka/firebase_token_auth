module FirebaseTokenAuth
  class Validator
    def self.validate(id_token)
      # ref. https://github.com/firebase/firebase-admin-node/blob/488f9318350c6b46af2e93b99907b9a02f170029/src/auth/token-verifier.ts
      # TODO: implement
    end

    def self.extract_kid(id_token)
      decoded = JWT.decode(id_token, nil, false, algorithm: ALGORITHM)[1]['kid']
      [decoded[1]['kid'], decoded]
    end
  end
end

