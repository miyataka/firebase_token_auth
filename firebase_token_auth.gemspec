require_relative 'lib/firebase_token_auth/version'

Gem::Specification.new do |spec|
  spec.name          = 'firebase_token_auth'
  spec.version       = FirebaseTokenAuth::VERSION
  spec.authors       = ['miyataka']
  spec.email         = ['voyager.3taka28@gmail.com']

  spec.summary       = 'Firebase Authentication API wrapper for serverside. It support custom token auth.'
  spec.description   = 'Firebase Authentication API wrapper for serverside. It support custom token auth. Of course it has id_token verify feature.'
  spec.homepage      = 'https://github.com/miyataka/firebase_token_auth'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.6.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'google-apis-identitytoolkit_v3'
  spec.add_dependency 'jwt'
end
