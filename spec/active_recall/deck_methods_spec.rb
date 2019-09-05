# frozen_string_literal: true

require 'spec_helper'

describe ActiveRecall::DeckMethods do
  let(:word) do
    Word.create!(
      kanji: '日本語',
      kana: 'にほんご',
      translation: 'Japanese language'
    )
  end
  let(:user) { User.create!(name: 'Robert') }

  describe '#words' do
    it 'should return an empty list when empty' do
      expect(user.words).to eq([])
    end

    it 'should allow access of word stats' do
      user.words << word
      expect(word.stats).to be
    end
  end
end
