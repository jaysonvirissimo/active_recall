# frozen_string_literal: true

require "active_record"
require "sqlite3"
require "active_recall"

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  # ActiveRecall tables
  create_table :active_recall_decks do |t|
    t.references :user, polymorphic: true
    t.timestamps
  end
  add_index :active_recall_decks, %i[user_id user_type]

  create_table :active_recall_items do |t|
    t.references :deck
    t.references :source, polymorphic: true
    t.integer :box, default: 0
    t.integer :times_right, default: 0
    t.integer :times_wrong, default: 0
    t.timestamp :last_reviewed
    t.timestamp :next_review
    t.timestamps
  end
  add_index :active_recall_items, %i[source_id source_type]

  # Test application tables
  create_table :words do |t|
    t.string :kanji
    t.string :kana
    t.string :translation
    t.timestamps
  end

  create_table :users do |t|
    t.string :name
    t.timestamps
  end
end

# Test application models
class Word < ActiveRecord::Base
  def to_s
    "#{kanji} (#{kana}) - #{translation}"
  end
end

class User < ActiveRecord::Base
  has_deck :words
end
