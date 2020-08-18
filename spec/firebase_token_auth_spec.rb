require 'pry-byebug'

RSpec.describe FirebaseTokenAuth do
  it 'has a version number' do
    expect(FirebaseTokenAuth::VERSION).not_to be nil
  end

  let!(:test_uid) { ENV['TEST_UID'] }
  let!(:test_user_email) { ENV['TEST_USER_EMAIL'] }

  context 'FirebaseTokenAuth::Client' do
    before do
      FirebaseTokenAuth.configure do |config|
        config.project_id = ENV['TEST_PROJECT_ID']
      end
    end

    context '#create_custom_token' do
      it 'smoke test' do
        client = FirebaseTokenAuth.new
        c_token = client.create_custom_token(test_uid)
        res_json = fetch_id_token(c_token)
        expect(res_json['idToken'].is_a?(String)).to be true
        expect(res_json['error']).to be nil
        TEST_ID_TOKEN = res_json['idToken']
      end
    end

    context '#verify_id_token' do
      it 'smoke test' do
        client = FirebaseTokenAuth.new
        result = client.verify_id_token(TEST_ID_TOKEN)
        expect(result.uid).not_to be nil
        expect(result.uid.is_a?(String)).to be true
        expect(result.id_token.payload['sub']).to eq result.uid
      end
    end

    context '#user_search_by_email' do
      it 'smoke test' do
        client = FirebaseTokenAuth.new
        result = client.user_search_by_email(test_user_email)
        expect(result.length).to eq 1
        expect(result.first[:email]).to eq test_user_email
      end
    end

    context '#user_search_by_uid' do
      it 'smoke test' do
        client = FirebaseTokenAuth.new
        result = client.user_search_by_uid(test_uid)
        expect(result.length).to eq 1
        expect(result.first[:local_id]).to eq test_uid
      end
    end

    context '#update_existing_account' do
      it 'smoke test' do
        client = FirebaseTokenAuth.new
        prev_email = test_user_email
        update_params = { display_name: SecureRandom.uuid, email: 'test@example.com' }
        result = client.update_user(test_uid, update_params)
        expect(result[:local_id]).to eq test_uid
        expect(result[:display_name]).to eq update_params[:display_name]
        expect(result[:email]).to eq update_params[:email]
        result = client.update_user(test_uid, { email: prev_email })
        expect(result[:local_id]).to eq test_uid
        expect(result[:email]).to eq prev_email
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
        FirebaseTokenAuth.configure { |config| config.project_id = ENV['TEST_PROJECT_ID'] }
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
        FirebaseTokenAuth.configure { |config| config.project_id = ENV['TEST_PROJECT_ID'] }
        client = FirebaseTokenAuth.new
        expect { client.create_custom_token(test_uid) }.to raise_error(FirebaseTokenAuth::ConfigurationError)
      end
    end
  end

  def fetch_id_token(custom_token)
    url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken\?key\=#{ENV['TEST_WEB_API_KEY']}"
    data = { token: custom_token, returnSecureToken: true }.to_json
    command_result = `curl -X POST #{url} -H 'Content-Type: application/json' --data \'#{data}\'`
    JSON.parse(command_result)
  end
end
