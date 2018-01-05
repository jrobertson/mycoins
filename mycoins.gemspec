Gem::Specification.new do |s|
  s.name = 'mycoins'
  s.version = '0.1.0'
  s.summary = 'mycoins'
  s.authors = ['James Robertson']
  s.files = Dir['lib/mycoins.rb']
  s.add_runtime_dependency('dynarex', '~> 1.7', '>=1.7.27')
  s.add_runtime_dependency('cryptocoin_fanboi', '~> 0.2', '>=0.2.3')
  s.signing_key = '../privatekeys/mycoins.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/mycoins'
end