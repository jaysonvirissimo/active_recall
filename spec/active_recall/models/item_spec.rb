# frozen_string_literal: true

require "spec_helper"
require "active_support/testing/time_helpers"

describe ActiveRecall::Item do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { User.create!(name: "Robert") }
  let(:word) do
    Word.create!(
      kanji: "日本語",
      kana: "にほんご",
      translation: "Japanese language"
    )
  end

  before(:each) { user.words << word }

  describe "#words" do
    it "should present a list of all words" do
      expect(user.words).to eq([word])
      expect(user.words.count).to eq(1)
    end

    describe ".untested" do
      it "should start off in the untested stack" do
        expect(user.words.untested).to eq([word])
      end
    end

    describe ".known" do
      it "correct answer should move it up one stack" do
        user.right_answer_for!(word)
        expect(user.words.untested).to eq([])
        expect(user.words.box(1)).to eq([word])
        expect(user.words.known).to eq([word])
      end
    end

    describe ".failed" do
      it "incorrect answer should move it to the failed stack" do
        user.wrong_answer_for!(word)
        expect(user.words.untested).to eq([])
        expect(user.words.failed).to eq([word])
        expect(word.stats.times_wrong).to eq(1)
      end
    end
  end

  describe ".stats" do
    describe ".next_review" do
      it "when untested, next study time should be nil" do
        expect(word.stats.next_review).not_to be
      end

      it "when correct, next study time should gradually increase" do
        user.right_answer_for!(word)
        stats = word.stats
        expect(stats.next_review).to eq(stats.last_reviewed + 3.days)
        expect(stats.times_right).to eq(1)
        user.right_answer_for!(word)
        stats.reload
        expect(stats.next_review).to eq(stats.last_reviewed + 7.days)
        expect(stats.times_right).to eq(2)
        user.right_answer_for!(word)
        stats.reload
        expect(stats.next_review).to eq(stats.last_reviewed + 14.days)
        user.right_answer_for!(word)
        stats.reload
        expect(stats.next_review).to eq(stats.last_reviewed + 30.days)
        user.right_answer_for!(word)
        stats.reload
        expect(stats.next_review).to eq(stats.last_reviewed + 60.days)
        user.right_answer_for!(word)
        stats.reload
        expect(stats.next_review).to eq(stats.last_reviewed + 120.days)
        user.right_answer_for!(word)
        stats.reload
        expect(stats.next_review).to eq(stats.last_reviewed + 240.days)
      end

      it "words should expire and move from known to expired" do
        future_time = Time.current + 4.days

        user.right_answer_for!(word)
        expect(user.words.known).to eq([word])

        travel_to(future_time) do
          expect(user.words.known).to eq([])
          expect(user.words.expired).to eq([word])
        end
      end
    end
  end
end
