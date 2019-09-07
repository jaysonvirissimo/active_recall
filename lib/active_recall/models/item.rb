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
      update!(LeitnerSystem.right(self))
    end

    def wrong!
      update!(LeitnerSystem.wrong(self))
    end
  end
end
