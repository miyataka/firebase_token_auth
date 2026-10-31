require 'webmock/rspec'
require 'openssl'
require 'jwt'
require 'json'

WebMock.disable_net_connect!

module OfflineFirebase
  KEY = OpenSSL::PKey::RSA.new(2048)
  PROJECT = 'offline-test-project'.freeze
  UID = 'offline-test-user'.freeze
  EMAIL = 'user@example.invalid'.freeze
  CERTIFICATE = OpenSSL::X509::Certificate.new.tap do |certificate|
    certificate.version = 2
    certificate.serial = 1
    certificate.subject = OpenSSL::X509::Name.parse('/CN=offline-test')
    certificate.issuer = certificate.subject
    certificate.public_key = KEY.public_key
    certificate.not_before = Time.now - 60
    certificate.not_after = Time.now + 3600
    certificate.sign(KEY, OpenSSL::Digest::SHA256.new)
  end

  def self.id_token
    JWT.encode({ sub: UID, aud: PROJECT, iss: "https://securetoken.google.com/#{PROJECT}",
                 iat: Time.now.to_i - 1, exp: Time.now.to_i + 3600 }, KEY, 'RS256', kid: 'offline-key')
  end
end

RSpec.configure do |config|
  config.before do
    ENV['TEST_UID'] = OfflineFirebase::UID
    ENV['TEST_USER_EMAIL'] = OfflineFirebase::EMAIL
    ENV['TEST_PROJECT_ID'] = OfflineFirebase::PROJECT
    ENV['TEST_WEB_API_KEY'] = 'offline-api-key'
    ENV['GOOGLE_ACCOUNT_TYPE'] = 'service_account'
    ENV['GOOGLE_CLIENT_ID'] = '123456789'
    ENV['GOOGLE_CLIENT_EMAIL'] = 'test@offline-test-project.iam.gserviceaccount.com'
    ENV['GOOGLE_PRIVATE_KEY'] = OfflineFirebase::KEY.to_pem
    FirebaseTokenAuth.configure { |c| c.project_id = OfflineFirebase::PROJECT; c.json_key_io = nil }
    headers = { 'Content-Type' => 'application/json' }
    stub_request(:get, FirebaseTokenAuth::PublicKeyManager::PUBLIC_KEY_URL)
      .to_return(status: 200, headers: headers.merge('Cache-Control' => 'max-age=3600'),
                 body: { 'offline-key' => OfflineFirebase::CERTIFICATE.to_pem }.to_json)
    stub_request(:post, %r{\Ahttps://(?:oauth2.googleapis.com/token|www.googleapis.com/oauth2/v4/token)\z})
      .to_return(status: 200, headers: headers, body: { access_token: 'offline-access-token', expires_in: 3600, token_type: 'Bearer' }.to_json)
    verify_response = { idToken: OfflineFirebase.id_token, refreshToken: 'offline-refresh-token' }.to_json
    stub_request(:post, 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=offline-api-key')
      .with do |request|
        token = JSON.parse(request.body).fetch('token')
        payload = JWT.decode(token, OfflineFirebase::KEY.public_key, true, algorithm: 'RS256').first
        payload['uid'] == OfflineFirebase::UID
      end.to_return(status: 200, headers: headers, body: verify_response)
    stub_request(:post, %r{\Ahttps://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyCustomToken(?:\?.*)?\z})
      .with do |request|
        token = JSON.parse(request.body).fetch('token')
        JWT.decode(token, OfflineFirebase::KEY.public_key, true, algorithm: 'RS256').first['uid'] == OfflineFirebase::UID
      end.to_return(status: 200, headers: headers, body: verify_response)
    stub_request(:post, %r{\Ahttps://www.googleapis.com/identitytoolkit/v3/relyingparty/getAccountInfo(?:\?.*)?\z})
      .with do |request|
        payload = JSON.parse(request.body)
        payload['email'] == [OfflineFirebase::EMAIL] || payload['localId'] == [OfflineFirebase::UID]
      end.to_return(status: 200, headers: headers, body: { users: [{ localId: OfflineFirebase::UID, email: OfflineFirebase::EMAIL }] }.to_json)
    stub_request(:post, %r{\Ahttps://www.googleapis.com/identitytoolkit/v3/relyingparty/setAccountInfo(?:\?.*)?\z})
      .with { |request| JSON.parse(request.body)['localId'] == OfflineFirebase::UID }
      .to_return do |request|
        payload = JSON.parse(request.body)
        { status: 200, headers: headers, body: payload.to_json }
      end
  end
end
