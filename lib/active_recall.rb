# frozen_string_literal: true

require "active_recall/base"
require "active_recall/deck_methods"
require "active_recall/item_methods"
require "active_recall/algorithms/fibonacci_sequence"
require "active_recall/algorithms/leitner_system"
require "active_recall/algorithms/soft_leitner_system"
require "active_recall/configuration"
require "active_recall/models/deck"
require "active_recall/models/item"
require "active_recall/version"

ActiveRecord::Base.include ActiveRecall::Base

module ActiveRecall
  class << self
    attr_writer :configuration
  end

  def self.configure
    yield(configuration)
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end
end
