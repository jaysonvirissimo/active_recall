# frozen_string_literal: true

module ActiveRecall
  module ItemMethods
    def right_answer_for!(item)
      i = deck.items.where(source_id: item.id).first
      i.right!
      i.save!
    end

    def wrong_answer_for!(item)
      i = deck.items.where(source_id: item.id).first
      i.wrong!
      i.save!
    end
  end
end
