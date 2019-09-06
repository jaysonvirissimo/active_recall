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

    DELAYS = [3, 7, 14, 30, 60, 120, 240].freeze

    def right!
      self[:box] += 1
      self.times_right += 1
      self.last_reviewed = Time.now
      self.next_review = last_reviewed + DELAYS[[DELAYS.count, box].min - 1].days
      save!
    end

    def wrong!
      self[:box] = 0
      self.times_wrong += 1
      self.last_reviewed = Time.now
      self.next_review = nil
      save!
    end
  end
end
