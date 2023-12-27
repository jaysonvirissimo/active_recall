# frozen_string_literal: true

module ActiveRecall
  class SoftLeitnerSystem
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
      self.box = [box + 1, DELAYS.count].min

      {
        box: box,
        times_right: times_right + 1,
        times_wrong: times_wrong,
        last_reviewed: current_time,
        next_review: next_review
      }
    end

    def wrong
      self.box = [box - 1, 0].max

      {
        box: box,
        times_right: times_right,
        times_wrong: times_wrong + 1,
        last_reviewed: current_time,
        next_review: next_review
      }
    end

    private

    DELAYS = [3, 7, 14, 30, 60, 120, 240].freeze
    REQUIRED_ATTRIBUTES = [:box, :times_right, :times_wrong].freeze

    attr_accessor :box
    attr_reader :current_time, :times_right, :times_wrong

    def next_review
      (current_time + DELAYS[[DELAYS.count, box].min - 1].days)
    end
  end
end
