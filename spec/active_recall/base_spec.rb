# frozen_string_literal: true

require 'spec_helper'

describe ActiveRecall::Base do
  let(:user) { User.create!(name: 'Robert') }

  describe '#has_deck' do
    it 'should add a decks method with name' do
      expect(user).to respond_to(:words)
    end
  end
end
