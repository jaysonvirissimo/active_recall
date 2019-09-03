# -*- encoding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'lib', 'active_recall', 'version')

Gem::Specification.new do |gem|
  gem.authors       = ["Robert Gravina", "Jayson Virissimo"]
  gem.email         = ["robert.gravina@gmail.com", "jayson.virissimo@asu.edu"]
  gem.description   = %q{ActiveRecall - a simple spaced-repetition system for Active Record models.}
  gem.summary       = %q{ActiveRecall is a simple spaced-repetition system for learning items, such as words and definitions in a foreign language, which you supply as Active Record models.}
  gem.homepage      = "https://github.com/rgravina/active_recall"
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "active_recall"
  gem.require_paths = ["lib"]
  gem.version       = ActiveRecall::VERSION

  gem.add_runtime_dependency 'activesupport'
  gem.add_runtime_dependency 'activerecord', '~> 5.2.3'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rdoc'
  gem.add_development_dependency 'sqlite3'
  gem.add_development_dependency 'timecop'

  gem.require_path = 'lib'
  gem.files = %w(README.md Rakefile) + Dir.glob("{lib,spec}/**/*")
end
