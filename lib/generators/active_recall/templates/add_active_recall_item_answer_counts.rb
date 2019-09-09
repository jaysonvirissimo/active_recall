# frozen_string_literal: true

class AddActiveRecallItemAnswerCounts < ActiveRecord::Migration[5.2]
  def self.up
    add_column :active_recall_items, :times_right, :integer, default: 0
    add_column :active_recall_items, :times_wrong, :integer, default: 0
  end

  def self.down
    remove_column :active_recall_items, :times_right
    remove_column :active_recall_items, :times_wrong
  end
end
