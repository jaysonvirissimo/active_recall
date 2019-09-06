# frozen_string_literal: true

module ActiveRecall
  module Base
    extend ActiveSupport::Concern
    module ClassMethods
      def has_deck(name)
        define_method(:deck_name) { name }
        include ActiveRecall::DeckMethods
        include ActiveRecall::ItemMethods
        define_method(name) { deck }
        after_destroy(:remove_deck)
      end
    end
  end
end
