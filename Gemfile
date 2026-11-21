source 'https://rubygems.org'

# Specify your gem's dependencies in firebase_token_auth.gemspec
gemspec

gem 'webmock', '~> 3.18'
gem 'rake', '~> 12.0'
gem 'rspec', '~> 3.0'

# multi_json releases supporting Ruby < 3.2 pass JSON.parse options positionally.
# Keep the legacy Ruby test dependency stack on the compatible JSON API.
gem 'json', '< 3' if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.2')
