# frozen_string_literal: true

class AddActiveRecallItemEasinessFactor < ActiveRecord::Migration[5.2]
  def self.up
    add_column :active_recall_items, :easiness_factor, :float, default: 2.5
  end

  def self.down
    remove_column :active_recall_items, :easiness_factor
  end
end
