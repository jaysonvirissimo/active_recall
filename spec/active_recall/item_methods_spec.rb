# frozen_string_literal: true

require "spec_helper"

describe ActiveRecall::ItemMethods do
  let(:user) { User.create!(name: "Test User") }
  let(:item) { Word.create!(kanji: "漢字", kana: "かんじ", translation: "Kanji") }

  before do
    user.words << item
  end

  describe "#right_answer_for!" do
    it "calls right! on the corresponding item" do
      expect_any_instance_of(ActiveRecall::Item).to receive(:right!).and_call_original
      user.right_answer_for!(item)
    end
  end

  describe "#wrong_answer_for!" do
    it "calls wrong! on the corresponding item" do
      expect_any_instance_of(ActiveRecall::Item).to receive(:wrong!).and_call_original
      user.wrong_answer_for!(item)
    end
  end

  xdescribe "#score!" do
    let(:grade) { 4 }

    it "calls score! on the corresponding item with the correct grade" do
      expect_any_instance_of(ActiveRecall::Item).to receive(:score!).with(grade).and_call_original
      user.score!(grade, item)
    end
  end
end
