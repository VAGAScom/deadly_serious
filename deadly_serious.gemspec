lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'deadly_serious/version'

Gem::Specification.new do |spec|
  spec.name          = 'deadly_serious'
  spec.version       = DeadlySerious::VERSION
  spec.authors       = ['Ronie Uliana']
  spec.email         = ['ronie.uliana@gmail.com']
  spec.description   = %q{Flow Based Programming Engine mechanically sympathetic to *nix.}
  spec.summary       = %q{Flow Based Programming engine that relies on named pipes and Linux processes (sorry, it not works on Windows right now). That means it uses 'mechanical sympathy' with the Operating System, i.e., the S.O. is *part* of the program, it's not something *below* it.}
  spec.homepage      = 'https://github.com/ruliana/deadly_serious'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/).reject { |file| file =~ /^examples\// }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '~> 2.1'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'

  spec.add_dependency 'json'
end
