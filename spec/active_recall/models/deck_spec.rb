# frozen_string_literal: true

require 'spec_helper'

describe ActiveRecall::Deck do
  let(:user) { User.create!(name: 'Robert') }
  let(:word) do
    Word.create!(
      kanji: '日本語',
      kana: 'にほんご',
      translation: 'Japanese language'
    )
  end

  describe '.review' do
    it 'should return an array of words to review' do
      user.words << word
      user.words << Word.create!(kanji: '日本語1', kana: 'にほんご1', translation: 'Japanese language')
      expect(user.words.known.count).to be_zero
      words = (user.words.untested + user.words.failed + user.words.expired).sort
      expect(words).to eq(user.words.review.sort)
    end

    it 'allows marking words right/wrong' do
      user.words << word
      user.words << Word.create!(kanji: '日本語1', kana: 'にほんご1', translation: 'Japanese language')
      expect(user.words.count).to eq(2)
      expect(user.words.review.count).to eq(2)
      user.words.review.each_with_index do |word, index|
        index.even? ? user.right_answer_for!(word) : user.wrong_answer_for!(word)
      end
      expect(user.words.review.count).to eq(1)
    end

    it 'should allow you to get one word only' do
      user.words << word
      user.words << Word.create!(kanji: '日本語1', kana: 'にほんご1', translation: 'Japanese language')
      expect(user.words.known.count).to be_zero
      word = user.words.next
      expect(user.words.untested).to include(word)
      user.right_answer_for!(word)
      word = user.words.next
      expect(user.words.untested).to include(word)
      user.right_answer_for!(word)
      expect(user.words.next).to_not be
    end
  end

  describe '#<<' do
    it 'should add words to the word list' do
      user.words << word
      expect(user.words).to eq([word])
    end

    it 'should raise an error if a duplicate word exists' do
      user.words << word
      expect(user.words).to eq([word])
      expect { user.words << word }.to raise_error(ArgumentError)
    end

    it 'should tell you what word was last added to the deck' do
      user.words << word
      expect(user.words.last).to eq(word)
    end
  end

  describe '#each' do
    it 'should be an iterator of words' do
      user.words << word

      collection = user.words.each_with_object([]) do |word, array|
        array << word
      end

      expect(collection).to eq([word])
    end
  end

  describe '#delete' do
    it 'should remove words from the word list (but not the model itself)' do
      user.words.delete(word)
      expect(user.words).not_to include(word)
      expect(user).not_to be_destroyed
    end
  end

  describe '#destroy' do
    context 'when there is a deck' do
      let(:deck) { user.words }

      it 'should delete itself and all item information when the source model is deleted' do
        deck && user.destroy
        expect(ActiveRecall::Deck.exists?(user_id: user.id)).to be_falsey
        expect(ActiveRecall::Item.exists?(deck_id: deck.id)).to be_falsey
        expect(word).to_not be_destroyed
      end
    end

    context 'before a deck has been created' do
      it 'does not raise an error' do
        expect { user.destroy }.not_to raise_error
      end
    end
  end
end
