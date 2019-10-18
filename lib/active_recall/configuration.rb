# frozen_string_literal: true

module ActiveRecall
  class Configuration
    attr_accessor :algorithm_class

    def initialize
      @algorithm_class = LeitnerSystem
    end
  end
end
