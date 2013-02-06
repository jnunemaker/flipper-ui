# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/ui/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["John Nunemaker"]
  gem.email         = ["nunemaker@gmail.com"]
  gem.description   = %q{UI for the Flipper gem}
  gem.summary       = %q{UI for the Flipper gem}
  gem.homepage      = "https://github.com/jnunemaker/flipper-ui"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "flipper-ui"
  gem.require_paths = ["lib"]
  gem.version       = Flipper::UI::VERSION

  gem.add_dependency 'rack'
  gem.add_dependency 'flipper', '~> 0.4.0'
end
