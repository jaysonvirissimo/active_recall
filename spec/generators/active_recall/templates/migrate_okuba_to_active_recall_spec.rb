# frozen_string_literal: true

require 'spec_helper'
require 'generators/active_recall/templates/migrate_okubo_to_active_recall'

describe MigrateOkuboToActiveRecall do
  let(:deck) do
    {
      'id' => 1,
      'user_type' => 'User',
      'user_id' => 1,
      'created_at' => '2018-07-19 05:32:49.404192',
      'updated_at' => '2018-07-19 05:32:49.404192'
    }
  end
  let(:first_item) do
    {
      'id' => 1,
      'deck_id' => 1,
      'source_type' => 'Word',
      'source_id' => 1,
      'box' => 1,
      'last_reviewed' => '2018-07-19 05:32:58.199127',
      'next_review' => '2018-07-22 05:32:58.199127',
      'created_at' => '2018-07-19 05:32:58.193354',
      'updated_at' => '2018-07-19 05:32:58.199858',
      'times_right' => 1,
      'times_wrong' => 0
    }
  end
  let(:second_item) do
    {
      'id' => 2,
      'deck_id' => 1,
      'source_type' => 'Word',
      'source_id' => 2,
      'box' => 2,
      'last_reviewed' => '2018-07-19 05:32:58.199127',
      'next_review' => '2018-07-22 05:32:58.199127',
      'created_at' => '2018-07-19 05:32:58.193354',
      'updated_at' => '2018-07-19 05:32:58.199858',
      'times_right' => 2,
      'times_wrong' => 1
    }
  end
  let(:decks) { double(to_a: [deck]) }
  let(:items) { double(to_a: [first_item, second_item]) }

  before do
    allow(ActiveRecord::Base.connection)
      .to receive(:execute)
      .with('SELECT  "okubo_decks".* FROM "okubo_decks"')
      .and_return(decks)
    allow(ActiveRecord::Base.connection)
      .to receive(:execute)
      .with('SELECT "okubo_items".* FROM "okubo_items"')
      .and_return(items)
  end

  describe '.up' do
    it 'migrates from Okubo to ActiveRecall while maintaining associations' do
      expect { described_class.up }.to change { ActiveRecall::Deck.count }.by(1)
      created_deck = ActiveRecall::Deck.order(:created_at).last
      expect(created_deck.user_type).to eq('User')
      created_items = created_deck.items.sort_by { |item| item['id'] }
      expect(created_items.first.box).to eq(1)
      expect(created_items.first.source_id).to eq(1)
      expect(created_items.last.box).to eq(2)
      expect(created_items.last.source_id).to eq(2)
    end
  end

  describe '.down' do
    it 'is a no-op' do
      expect(described_class.down).to eq(true)
    end
  end
end
