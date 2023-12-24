# frozen_string_literal: true

require "spec_helper"

describe ActiveRecall::ItemMethods do
  let(:user) { User.create!(name: "Test User") }
  let(:item) { Word.create!(kanji: "漢字", kana: "かんじ", translation: "Kanji") }

  before do
    user.words << item
  end

  describe "#right_answer_for!" do
    it "errors when tried without a binary algorithm" do
      ActiveRecall.configure do |config|
        @previous_algorithm_class = config.algorithm_class
        config.algorithm_class = ActiveRecall::SM2
      end

      expect { user.right_answer_for!(item) }.to raise_error(ActiveRecall::IncompatibleAlgorithmError)

      ActiveRecall.configure do |config|
        config.algorithm_class = @previous_algorithm_class
      end
    end
  end

  describe "#wrong_answer_for!" do
    it "errors when tried without a binary algorithm" do
      ActiveRecall.configure do |config|
        @previous_algorithm_class = config.algorithm_class
        config.algorithm_class = ActiveRecall::SM2
      end

      expect { user.wrong_answer_for!(item) }.to raise_error(ActiveRecall::IncompatibleAlgorithmError)

      ActiveRecall.configure do |config|
        config.algorithm_class = @previous_algorithm_class
      end
    end
  end

  describe "#score!" do
    let(:grade) { 4 }

    it "errors when tried without a binary algorithm" do
      expect { user.score!(grade, item) }.to raise_error(ActiveRecall::IncompatibleAlgorithmError)
    end
  end
end
