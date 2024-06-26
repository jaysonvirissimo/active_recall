# frozen_string_literal: true

module ActiveRecall
  class LeitnerSystem
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
        times_right: times_right + 1,
        times_wrong: times_wrong,
        last_reviewed: current_time,
        next_review: next_review
      }
    end

    def wrong
      {
        box: 0,
        times_right: times_right,
        times_wrong: times_wrong + 1,
        last_reviewed: current_time,
        next_review: nil
      }
    end

    private

    attr_reader :box, :current_time, :times_right, :times_wrong

    DELAYS = [3, 7, 14, 30, 60, 120, 240].freeze
    REQUIRED_ATTRIBUTES = [:box, :times_right, :times_wrong].freeze

    def next_review
      (current_time + DELAYS[[DELAYS.count, box + 1].min - 1].days)
    end
  end
end
