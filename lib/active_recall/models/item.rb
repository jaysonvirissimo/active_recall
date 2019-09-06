# frozen_string_literal: true

module ActiveRecall
  class Item < ActiveRecord::Base
    self.table_name = 'active_recall_items'
    belongs_to :deck
    belongs_to :source, polymorphic: true
    scope :untested, -> { where(['box = ? and last_reviewed is null', 0]) }
    scope :failed, -> { where(['box = ? and last_reviewed is not null', 0]) }
    scope :known, -> { where(['box > ? and next_review > ?', 0, Time.now]) }
    scope :expired, -> { where(['box > ? and next_review <= ?', 0, Time.now]) }

    def right!(current_time: Time.current)
      LeitnerSystem.new(self).right.save!
    end

    def wrong!(current_time: Time.current)
      LeitnerSystem.new(self).wrong.save!
    end

    class LeitnerSystem
      DELAYS = [3, 7, 14, 30, 60, 120, 240].freeze

      def initialize(item, current_time: Time.current)
        @item = item
        @current_time = current_time
      end

      def right
        item[:box] += 1
        item.times_right += 1
        item.last_reviewed = current_time
        item.next_review = item.last_reviewed + DELAYS[[DELAYS.count, item.box].min - 1].days
        item
      end

      def wrong
        item[:box] = 0
        item.times_wrong += 1
        item.last_reviewed = current_time
        item.next_review = nil
        item
      end

      private

      attr_reader :item, :current_time
    end
  end
end
