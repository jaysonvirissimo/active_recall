# frozen_string_literal: true

module ActiveRecall
  class FibonacciSequence
    def self.right(box:, current_time: Time.current, times_right:, times_wrong:)
      new(
        box: box,
        current_time: current_time,
        times_right: times_right,
        times_wrong: times_wrong
      ).right
    end

    def self.wrong(box:, current_time: Time.current, times_right:, times_wrong:)
      new(
        box: box,
        current_time: current_time,
        times_right: times_right,
        times_wrong: times_wrong
      ).wrong
    end

    def initialize(box:, current_time: Time.current, times_right:, times_wrong:)
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
        box: [0, box - 1].max,
        last_reviewed: current_time,
        next_review: nil,
        times_right: times_right,
        times_wrong: times_wrong + 1
      }
    end

    private

    attr_reader :box, :current_time, :times_right, :times_wrong

    def fibonacci_number_at(index)
      if (0..1).cover?(index)
        index
      else
        fibonacci_number_at(index - 1) + fibonacci_number_at(index - 2)
      end
    end

    def next_review
      current_time + fibonacci_number_at(box + 1).days
    end
  end
end
