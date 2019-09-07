# frozen_string_literal: true

class LeitnerSystem
  DELAYS = [3, 7, 14, 30, 60, 120, 240].freeze

  def initialize(item, current_time: Time.current)
    @item = item
    @current_time = current_time
  end

  def right
    {
      box: item.box + 1,
      times_right: item.times_right + 1,
      last_reviewed: current_time,
      next_review: next_review
    }
  end

  def wrong
    {
      box: 0,
      times_wrong: item.times_wrong + 1,
      last_reviewed: current_time,
      next_review: nil
    }
  end

  private

  attr_reader :item, :current_time

  def next_review
    (current_time + DELAYS[[DELAYS.count, item.box + 1].min - 1].days)
  end
end
