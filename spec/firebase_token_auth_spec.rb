require 'net/http'
require 'securerandom'

RSpec.describe FirebaseTokenAuth do
  it 'has a version number' do
    expect(FirebaseTokenAuth::VERSION).not_to be nil
  end

  let(:project_id) { ENV.fetch('TEST_PROJECT_ID') }

  context 'FirebaseTokenAuth::Client' do
    let(:client) { FirebaseTokenAuth.new }
    let(:test_uid) { ENV.fetch('TEST_UID') }
    let(:test_user_email) { ENV.fetch('TEST_USER_EMAIL') }
    let(:custom_token) { client.create_custom_token(test_uid) }

    before do
      FirebaseTokenAuth.configure do |config|
        config.project_id = project_id
      end
    end

    context '#create_custom_token' do
      it 'exchanges the signed custom token for a Firebase ID token' do
        expect(sign_in_with_custom_token(custom_token)).to be_a(String).and match(/\S/)
      end
    end

    context '#verify_custom_token' do
      it 'returns Firebase ID and refresh tokens' do
        result = client.verify_custom_token(custom_token)
        expect(client.verify_id_token(result.fetch(:id_token)).uid).to eq test_uid
        expect(result.fetch(:refresh_token)).to be_a(String).and match(/\S/)
      end
    end

    context '#verify_id_token' do
      it 'verifies a Firebase-issued ID token' do
        id_token = sign_in_with_custom_token(custom_token)
        result = client.verify_id_token(id_token)
        expect(result.uid).to eq test_uid
        expect(result.id_token.payload['sub']).to eq test_uid
      end
    end

    context '#user_search_by_email' do
      it 'finds the Firebase test user by email' do
        result = client.user_search_by_email(test_user_email)
        expect(result.length).to eq 1
        expect(result.first[:email]).to eq test_user_email
        expect(result.first[:local_id]).to eq test_uid
      end
    end

    context '#user_search_by_uid' do
      it 'finds the Firebase test user by UID' do
        result = client.user_search_by_uid(test_uid)
        expect(result.length).to eq 1
        expect(result.first[:local_id]).to eq test_uid
      end
    end

    context '#update_user' do
      it 'persists the display name and email in Firebase' do
        uid = "firebase-token-auth-test-#{SecureRandom.uuid}"
        sign_in_with_custom_token(client.create_custom_token(uid))
        user_created = true

        attributes = { display_name: 'Firebase integration test', email: "#{uid}@example.com" }
        expected = attributes.merge(local_id: uid)
        expect(client.update_user(uid, attributes)).to include(expected)
        expect(client.user_search_by_uid(uid)).to match([a_hash_including(expected)])
      ensure
        if user_created
          service = FirebaseTokenAuth::AdminClient.new(client.configuration).service
          service.delete_account(Google::Apis::IdentitytoolkitV3::DeleteAccountRequest.new(local_id: uid))
        end
      end
    end
  end

  context 'Exception Handling' do
    context 'project_id is not set' do
      it 'raise ConfigurationError' do
        FirebaseTokenAuth.configure { |config| config.project_id = nil }
        expect { FirebaseTokenAuth.new }.to raise_error(FirebaseTokenAuth::ConfigurationError)
      end
    end

    context 'call verify_id_token method with blank string' do
      it 'raise ArgumentError' do
        FirebaseTokenAuth.configure { |config| config.project_id = project_id }
        client = FirebaseTokenAuth.new
        expect { client.verify_id_token('') }.to raise_error(FirebaseTokenAuth::ArgumentError)
      end
    end

    context 'call create_custom_token method with incorrect configuration' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('GOOGLE_CLIENT_EMAIL').and_return(nil)
      end
      it 'raise ConfigurationError' do
        FirebaseTokenAuth.configure { |config| config.project_id = project_id }
        client = FirebaseTokenAuth.new
        expect { client.create_custom_token('test-user') }.to raise_error(FirebaseTokenAuth::ConfigurationError)
      end
    end
  end

  def sign_in_with_custom_token(custom_token)
    uri = URI('https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken')
    uri.query = URI.encode_www_form(key: ENV.fetch('TEST_WEB_API_KEY'))
    data = { token: custom_token, returnSecureToken: true }.to_json
    response = Net::HTTP.post(uri, data, 'Content-Type' => 'application/json')
    response.value
    JSON.parse(response.body).fetch('idToken')
  end
end
