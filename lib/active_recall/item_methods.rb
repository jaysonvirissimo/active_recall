# frozen_string_literal: true

module ActiveRecall
  module ItemMethods
    def right_answer_for!(item, current_time: Time.current)
      i = deck.items.where(source_id: item.id).first
      i.right!(current_time: current_time)
      i.save!
    end

    def wrong_answer_for!(item, current_time: Time.current)
      i = deck.items.where(source_id: item.id).first
      i.wrong!(current_time: current_time)
      i.save!
    end
  end
end
