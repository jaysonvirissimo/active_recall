# frozen_string_literal: true

require "spec_helper"

describe ActiveRecall::ItemMethods do
  let(:user) { User.create!(name: "Test User") }
  let(:item) { Word.create!(kanji: "漢字", kana: "かんじ", translation: "Kanji") }

  before do
    user.words << item
  end

  context "when configured with a binary algorithm" do
    describe "#right_answer_for!" do
      it "does not raise an error" do
        expect { user.right_answer_for!(item) }.not_to raise_error
      end
    end

    describe "#wrong_answer_for!" do
      it "does not raise an error" do
        expect { user.wrong_answer_for!(item) }.not_to raise_error
      end
    end

    describe "#score!" do
      let(:grade) { 4 }

      it "raises an error when called with a binary algorithm" do
        expect { user.score!(grade, item) }.to raise_error(ActiveRecall::IncompatibleAlgorithmError)
      end
    end
  end

  context "when configured with a gradable algorithm" do
    before do
      ActiveRecall.configure do |config|
        @previous_algorithm_class = config.algorithm_class
        config.algorithm_class = ActiveRecall::SM2
      end
    end

    after do
      ActiveRecall.configure do |config|
        config.algorithm_class = @previous_algorithm_class
      end
    end

    describe "#right_answer_for!" do
      it "raises an error when called with a gradable algorithm" do
        expect { user.right_answer_for!(item) }.to raise_error(ActiveRecall::IncompatibleAlgorithmError)
      end
    end

    describe "#wrong_answer_for!" do
      it "raises an error when called with a gradable algorithm" do
        expect { user.wrong_answer_for!(item) }.to raise_error(ActiveRecall::IncompatibleAlgorithmError)
      end
    end

    describe "#score!" do
      let(:grade) { 4 }

      it "raises an error due to calling score on the return value of update!" do
        expect { user.score!(grade, item) }.not_to raise_error
      end
    end
  end
end
