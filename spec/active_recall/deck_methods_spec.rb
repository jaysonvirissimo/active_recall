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

    describe '#stats' do
      let(:stats) do
        user.words << word
        word.stats
      end

      it 'should allow access of word stats' do
        expect(stats).to respond_to(:last_reviewed)
        expect(stats).to respond_to(:next_review)
        expect(stats).to respond_to(:times_right)
        expect(stats).to respond_to(:times_wrong)
      end
    end
  end
end
