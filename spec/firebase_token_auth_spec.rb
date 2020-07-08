require 'pry-byebug'

RSpec.describe FirebaseTokenAuth do
  it 'has a version number' do
    expect(FirebaseTokenAuth::VERSION).not_to be nil
  end

  let!(:test_uid) { ENV['TEST_UID'] }

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
  end

  def fetch_id_token(custom_token)
    url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken\?key\=#{ENV['TEST_WEB_API_KEY']}"
    data = { token: custom_token, returnSecureToken: true }.to_json
    command_result = `curl -X POST #{url} -H 'Content-Type: application/json' --data \'#{data}\'`
    JSON.parse(command_result)
  end
end
