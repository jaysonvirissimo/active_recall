# frozen_string_literal: true

module ActiveRecall
  module ItemMethods
    def right_answer_for!(item)
      deck.items.find_by(source_id: item.id).right!
    end

    def wrong_answer_for!(item)
      deck.items.find_by(source_id: item.id).wrong!
    end
  end
end
