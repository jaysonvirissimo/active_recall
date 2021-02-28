# frozen_string_literal: true

module ActiveRecall
  module DeckMethods
    def deck
      d = ActiveRecall::Deck.find_or_create_by(user_id: id, user_type: self.class.name)
      d.source_class.module_eval do
        def stats
          ActiveRecall::Item.find_by(source_id: id, source_type: self.class.name)
        end
      end
      d
    end

    def remove_deck
      ActiveRecall::Deck
        .where(user_id: id, user_type: self.class.name)
        .destroy_all
    end
  end
end
