# frozen_string_literal: true

module ActiveRecall
  class Item < ActiveRecord::Base
    self.table_name = "active_recall_items"

    belongs_to :deck

    scope :failed, -> { where(["box = ? and last_reviewed is not null", 0]) }
    scope :untested, -> { where(["box = ? and last_reviewed is null", 0]) }

    def self.expired(current_time: Time.current)
      where(["box > ? and next_review <= ?", 0, current_time])
    end

    def self.known(current_time: Time.current)
      where(["box > ? and next_review > ?", 0, current_time])
    end

    def score!(grade)
      if algorithm_class.type == :gradable
        update!(
          algorithm_class.score(**scoring_attributes.merge(grade: grade))
        )
      else
        raise IncompatibleAlgorithmError, "#{algorithm_class.name} is a not an gradable algorithm, so is not compatible with the #score! method"
      end
    end

    def source
      source_type.constantize.find(source_id)
    end

    def right!
      if algorithm_class.type == :binary
        update!(algorithm_class.right(**scoring_attributes))
      else
        raise IncompatibleAlgorithmError, "#{algorithm_class.name} is not a binary algorithm, so is not compatible with the #right! method"
      end
    end

    def wrong!
      if algorithm_class.type == :binary
        update!(algorithm_class.wrong(**scoring_attributes))
      else
        raise IncompatibleAlgorithmError, "#{algorithm_class.name} is not a binary algorithm, so is not compatible with the #wrong! method"
      end
    end

    private

    def algorithm_class
      ActiveRecall.configuration.algorithm_class
    end

    def scoring_attributes
      attributes
        .symbolize_keys
        .slice(*algorithm_class.required_attributes)
    end
  end
end
