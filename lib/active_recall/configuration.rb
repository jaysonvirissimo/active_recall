# frozen_string_literal: true

module ActiveRecall
  class Configuration
    attr_accessor :algorithm_class,
      :fsrs_request_retention,
      :fsrs_maximum_interval,
      :fsrs_weights

    def initialize
      @algorithm_class = LeitnerSystem
    end
  end
end
