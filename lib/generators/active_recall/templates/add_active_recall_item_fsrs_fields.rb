# frozen_string_literal: true

class AddActiveRecallItemFsrsFields < ActiveRecord::Migration[5.2]
  def self.up
    add_column :active_recall_items, :stability, :float
    add_column :active_recall_items, :difficulty, :float
    add_column :active_recall_items, :state, :integer, default: 0
    add_column :active_recall_items, :lapses, :integer, default: 0
    add_column :active_recall_items, :elapsed_days, :integer, default: 0
    add_column :active_recall_items, :scheduled_days, :integer, default: 0
  end

  def self.down
    remove_column :active_recall_items, :stability
    remove_column :active_recall_items, :difficulty
    remove_column :active_recall_items, :state
    remove_column :active_recall_items, :lapses
    remove_column :active_recall_items, :elapsed_days
    remove_column :active_recall_items, :scheduled_days
  end
end
