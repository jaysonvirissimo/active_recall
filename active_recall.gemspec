# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_recall/version"

Gem::Specification.new do |spec|
  spec.name = "active_recall"
  spec.version = ActiveRecall::VERSION
  spec.authors = ["Robert Gravina", "Jayson Virissimo"]
  spec.email = ["robert.gravina@gmail.com", "jayson.virissimo@asu.edu"]
  spec.summary = "A spaced-repetition system"
  spec.description = "A spaced-repetition system to be used with ActiveRecord models"
  spec.homepage = "https://github.com/jaysonvirissimo/active_recall"
  spec.license = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org/"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", ">= 12.0"
  spec.add_development_dependency "rdoc"
  spec.add_development_dependency "rspec", ">= 3.0"
  spec.add_development_dependency "sqlite3"
  spec.add_runtime_dependency "activerecord", ">= 6.0", "<= 7.1"
  spec.add_runtime_dependency "activesupport", ">= 6.0", "<= 7.1"
  spec.required_ruby_version = ">= 3.0"
end
