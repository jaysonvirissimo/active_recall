# frozen_string_literal: true

module ActiveRecall
  class FibonacciSequence
    def self.required_attributes
      REQUIRED_ATTRIBUTES
    end

    def self.right(box:, times_right:, times_wrong:, current_time: Time.current)
      new(
        box: box,
        current_time: current_time,
        times_right: times_right,
        times_wrong: times_wrong
      ).right
    end

    def self.type
      :binary
    end

    def self.wrong(box:, times_right:, times_wrong:, current_time: Time.current)
      new(
        box: box,
        current_time: current_time,
        times_right: times_right,
        times_wrong: times_wrong
      ).wrong
    end

    def initialize(box:, times_right:, times_wrong:, current_time: Time.current)
      @box = box
      @current_time = current_time
      @times_right = times_right
      @times_wrong = times_wrong
    end

    def right
      {
        box: box + 1,
        last_reviewed: current_time,
        next_review: next_review,
        times_right: times_right + 1,
        times_wrong: times_wrong
      }
    end

    def wrong
      {
        box: 0,
        last_reviewed: current_time,
        next_review: nil,
        times_right: times_right,
        times_wrong: times_wrong + 1
      }
    end

    private

    attr_reader :box, :current_time, :times_right, :times_wrong

    REQUIRED_ATTRIBUTES = [:box, :times_right, :times_wrong].freeze
    SEQUENCE = [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181, 6765].freeze

    def fibonacci_number_at(index)
      return SEQUENCE[index] if (0...SEQUENCE.length).cover?(index)

      @fibonacci_cache ||= {}
      @fibonacci_cache[index] ||= fibonacci_number_at(index - 1) + fibonacci_number_at(index - 2)
    end

    def next_review
      current_time + fibonacci_number_at(box + 1).days
    end
  end
end
