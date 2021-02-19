# frozen_string_literal: true

module ActiveRecall
  module ItemMethods
    def right_answer_for!(item)
      i = deck.items.find_by(source_id: item.id)
      i.right!
      i.save!
    end

    def wrong_answer_for!(item)
      i = deck.items.find_by(source_id: item.id)
      i.wrong!
      i.save!
    end
  end
end
