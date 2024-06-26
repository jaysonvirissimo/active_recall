# frozen_string_literal: true

module ActiveRecall
  class Deck < ActiveRecord::Base
    include Enumerable
    include ActiveRecall::Base
    self.table_name = "active_recall_decks"
    belongs_to :user, polymorphic: true
    has_many :items, class_name: "ActiveRecall::Item", dependent: :destroy

    def each
      _items.find_each { |item| yield item }
    end

    def ==(other)
      _items == other
    end

    def <<(source)
      attributes = {deck: self, source_id: source.id, source_type: source.class.name}

      if ActiveRecall::Item.exists?(attributes)
        raise ArgumentError, "Word already in the stack"
      end

      items << ActiveRecall::Item.new(attributes)
    end

    def self.add_deck(user)
      create!(user)
    end

    def delete(source)
      ActiveRecall::Item
        .find_by(deck: self, source_id: source.id, source_type: source.class.name)
        .destroy
    end

    def review
      source_class.where(id: _review.select(:source_id))
    end

    def next
      _review.first.try(:source)
    end

    def last
      items.order("created_at desc").limit(1).first.try(:source)
    end

    def untested
      source_class.where(id: items.untested.select(:source_id))
    end

    def failed
      source_class.where(id: items.failed.select(:source_id))
    end

    def known
      source_class.where(id: items.known.select(:source_id))
    end

    def expired
      source_class.where(id: items.expired.select(:source_id))
    end

    def box(number)
      source_class.where(id: items.where(box: number).select(:source_id))
    end

    def source_class
      user.deck_name.to_s.singularize.titleize.constantize
    end

    private

    def _items
      source_class.where(id: items.select(:source_id))
    end

    def _review
      items
        .untested
        .or(items.failed)
        .or(items.expired)
        .order(random_order_function)
    end

    def random_order_function
      Arel.sql(mysql? ? "RAND()" : "random()")
    end

    def mysql?
      source_class.connection.adapter_name == "Mysql2"
    end
  end
end
