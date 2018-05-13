Gem::Specification.new do |s|
  s.name = 'mycoins'
  s.version = '0.3.8'
  s.summary = 'The mycoins gem calculates the current value ' + 
      'of your crypto-currency portfolio.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/mycoins.rb']
  s.add_runtime_dependency('dynarex', '~> 1.7', '>=1.7.29')
  s.add_runtime_dependency('cryptocoin_fanboi', '~> 0.5', '>=0.5.4')
  s.signing_key = '../privatekeys/mycoins.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/mycoins'
end
