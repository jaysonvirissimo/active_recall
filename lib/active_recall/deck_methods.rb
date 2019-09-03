module ActiveRecall
  module DeckMethods
    def deck
      d = ActiveRecall::Deck.where(:user_id => self.id, :user_type => self.class.name).first_or_create
      d.source_class.module_eval do
        def stats
         ActiveRecall::Item.where(source_id: self.id, source_type: self.class.name).first
        end
      end
      d
    end

    def remove_deck
      deck = ActiveRecall::Deck.where(user_id: self.id, user_type: self.class.name).first
      deck.destroy
    end
  end
end
