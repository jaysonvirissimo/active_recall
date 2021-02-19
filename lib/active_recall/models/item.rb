# frozen_string_literal: true

module ActiveRecall
  class Item < ActiveRecord::Base
    self.table_name = 'active_recall_items'

    belongs_to :deck

    scope :failed, -> { where(['box = ? and last_reviewed is not null', 0]) }
    scope :untested, -> { where(['box = ? and last_reviewed is null', 0]) }

    def self.expired(current_time: Time.current)
      where(['box > ? and next_review <= ?', 0, current_time])
    end

    def self.known(current_time: Time.current)
      where(['box > ? and next_review > ?', 0, current_time])
    end

    def source
      source_type.constantize.find(source_id)
    end

    def right!
      update!(algorithm_class.right(**scoring_attributes))
    end

    def wrong!
      update!(algorithm_class.wrong(**scoring_attributes))
    end

    private

    def algorithm_class
      ActiveRecall.configuration.algorithm_class
    end

    def scoring_attributes
      attributes.symbolize_keys.slice(:box, :times_right, :times_wrong)
    end
  end
end
