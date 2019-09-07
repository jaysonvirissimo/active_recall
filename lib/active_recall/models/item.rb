# frozen_string_literal: true

module ActiveRecall
  class Item < ActiveRecord::Base
    self.table_name = 'active_recall_items'
    belongs_to :deck
    belongs_to :source, polymorphic: true
    scope :untested, -> { where(['box = ? and last_reviewed is null', 0]) }
    scope :failed, -> { where(['box = ? and last_reviewed is not null', 0]) }
    scope :known, lambda { |current_time: Time.current|
      where(['box > ? and next_review > ?', 0, current_time])
    }
    scope :expired, lambda { |current_time: Time.current|
      where(['box > ? and next_review <= ?', 0, current_time])
    }

    def right!
      update!(LeitnerSystem.new(self).right)
    end

    def wrong!
      update!(LeitnerSystem.new(self).wrong)
    end

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
          next_review: (current_time + DELAYS[[DELAYS.count, item.box + 1].min - 1].days)
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
    end
  end
end
