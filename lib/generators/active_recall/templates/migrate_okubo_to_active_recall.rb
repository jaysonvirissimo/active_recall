# frozen_string_literal: true

class MigrateOkuboToActiveRecall < ActiveRecord::Migration[5.2]
  DECK_SQL = 'SELECT  "okubo_decks".* FROM "okubo_decks"'
  ITEM_SQL = 'SELECT "okubo_items".* FROM "okubo_items"'

  def self.up
    connection = ActiveRecord::Base.connection
    decks = connection.execute(DECK_SQL).to_a.map(&:symbolize_keys)
    items = connection.execute(ITEM_SQL).to_a.map(&:symbolize_keys)

    decks.each do |deck_attributes|
      deck_create_attributes = deck_attributes.except(:id, :created_at, :updated_at)
      deck = ActiveRecall::Deck.create!(deck_create_attributes)

      items.select do |item_attributes|
        deck_attributes[:id] == item_attributes[:deck_id]
      end.each do |item_attributes|
        item_create_attributes = item_attributes
                                 .except(:id, :created_at, :updated_at)
                                 .merge(deck_id: deck.id)
        ActiveRecall::Item.create!(item_create_attributes)
      end
    end
  end

  def self.down
    true
  end
end
