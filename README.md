# FirebaseTokenAuth

FirebaseTokenAuth is an Firebase Auth Client. It supports below.
- verify id_token method
- create custom token
- fetch user info by uid/email
- update user info

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'firebase_token_auth'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install firebase_token_auth

## Usage

on Rails, config/initializers/firebase_token_auth.rb
```ruby
FirebaseTokenAuth.configure do |config|
  ## for id_token_verify
  # firebase web console => project settings => general => project ID
  config.project_id = "your_project_id" # required

  # firebase web console => project settings => service account => firebase admin sdk => generate new private key
  # pass string of path to credential file to config.json_key_io
  config.json_key_io = "#{Rails.root}/path/to/service_account_credentials.json"
  # Or content of json key file wrapped with StringIO
  # config.json_key_io = StringIO.new('{ ... }')

  # Or set environment variables
  # ENV['GOOGLE_ACCOUNT_TYPE'] = 'service_account'
  # ENV['GOOGLE_CLIENT_ID'] = '000000000000000000000'
  # ENV['GOOGLE_CLIENT_EMAIL'] = 'xxxx@xxxx.iam.gserviceaccount.com'
  # ENV['GOOGLE_PRIVATE_KEY'] = '-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n\'
end
```
for more detail. see [here](https://github.com/googleapis/google-auth-library-ruby#example-service-account).

### token verify
```ruby
require 'firebase_token_auth'

FirebaseTokenAuth.configure do |config|
  config.project_id = 'your_project_id'
end

client = Firebase.build
result = client.verify_id_token(id_token)

puts result.uid
# => "hMPHt8RyDpOsHi1oH5XaVirSYyq2"

puts result.id_token.payload # you can see decoded id_token payload
# => {"iss"=>"https://securetoken.google.com/<your_project_id>",
#  "aud"=>"<your_project_id>",
#  "auth_time"=>1594494935,
#  "user_id"=>"hMPHt8RyDpOsHi1oH5XaVirSYyq2",
#  "sub"=>"hMPHt8RyDpOsHi1oH5XaVirSYyq2",
#  "iat"=>1594494935,
#  "exp"=>1594498535,
#  "email"=>"<your_user_email>",
#  "email_verified"=>false,
#  "firebase"=>{"identities"=>{"email"=>["<your_user_email>"]}, "sign_in_provider"=>"custom"}}

puts result.id_token.header
# => {"alg"=>"RS256", "kid"=>"7623e10a045140f1cfd4be0466cf80352b59f81e", "typ"=>"JWT"}
```

### custom token create
```ruby
require 'firebase_token_auth'

FirebaseTokenAuth.configure do |config|
  config.project_id = 'your_project_id'
  config.json_key_io = "#{Rails.root}/path/to/service_account_credentials.json"
end

client = FirebaseTokenAuth.new
c_token = client.create_custom_token(test_uid)
puts c_token
# => "eyJhbGciOXXX.eyJpc3MiOiJmaXJlYmFzXXXX.v7y7LoBXXXXX" # dummy
```

### fetch users info from firebase
```ruby
require 'firebase_token_auth'

FirebaseTokenAuth.configure do |config|
  config.project_id = 'your_project_id'
  config.json_key_io = "#{Rails.root}/path/to/service_account_credentials.json"
end

client = FirebaseTokenAuth.new
result = client.user_search_by_email(test_user_email)
# result = client.user_search_by_uid(test_uid)
puts result
# => [{:created_at=>1594132097140,
#   :custom_auth=>true,
#   :disabled=>false,
#   :email=>"<your_user_email>",
#   :email_verified=>false,
#   :last_login_at=>1594495792373,
#   :local_id=>"hMPHt8RyDpOsHi1oH5XaVirSYyq2",
#   :password_hash=>"REDACTED",
#   :password_updated_at=>1594132097140,
#   :provider_user_info=>
#    [{:email=>"<your_user_email>",
#      :federated_id=>"<your_user_email>",
#      :provider_id=>"password",
#      :raw_id=>"<your_user_email>"}],
#   :valid_since=>1594132097}]
```

### update user info
```ruby
require 'firebase_token_auth'

FirebaseTokenAuth.configure do |config|
  config.project_id = 'your_project_id'
  config.json_key_io = "#{Rails.root}/path/to/service_account_credentials.json"
end

client = FirebaseTokenAuth.new
# NOTE: parameter_name is snake_case
update_params = { # ref. https://firebase.google.com/docs/reference/rest/auth#section-update-profile
  display_name: 'updated_name',
}
result = client.update_user(test_uid, update_params)
puts result
# => {:display_name=>"updated_name",
#  :email=>"<your_user_email>",
#  :email_verified=>false,
#  :kind=>"identitytoolkit#SetAccountInfoResponse",
#  :local_id=>"hMPHt8RyDpOsHi1oH5XaVirSYyq2",
#  :password_hash=>"REDACTED",
#  :provider_user_info=>[{:display_name=>"updated_name", :federated_id=>"<your_user_email>", :provider_id=>"password"}]}
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/miyataka/firebase_token_auth.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
