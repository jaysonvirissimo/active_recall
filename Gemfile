# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gemspec

# TODO: Remove conditional dependency after dropping support for Ruby 3.2
begin
  ruby_version = Gem::Version.new(RUBY_VERSION)
  if ruby_version >= Gem::Version.new("3.4.0")
    gem "nokogiri", ">= 1.16.2"
  end
  if ruby_version >= Gem::Version.new("4.0.0")
    gem "ostruct"
    gem "logger"
  end
rescue
end
