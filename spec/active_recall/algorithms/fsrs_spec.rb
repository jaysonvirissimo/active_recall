# frozen_string_literal: true

require "spec_helper"

describe ActiveRecall::FSRS do
  let(:current_time) { Time.utc(2026, 4, 25, 12, 0, 0) }

  let(:new_card_params) do
    {
      box: 0,
      stability: nil,
      difficulty: nil,
      state: 0,
      lapses: 0,
      elapsed_days: 0,
      scheduled_days: 0,
      times_right: 0,
      times_wrong: 0,
      last_reviewed: nil,
      current_time: current_time
    }
  end

  before do
    ActiveRecall.configuration.fsrs_request_retention = nil
    ActiveRecall.configuration.fsrs_maximum_interval = nil
    ActiveRecall.configuration.fsrs_weights = nil
  end

  describe ".required_attributes" do
    specify do
      expect(described_class.required_attributes).to contain_exactly(
        :box, :stability, :difficulty, :state, :lapses,
        :elapsed_days, :scheduled_days,
        :times_right, :times_wrong, :last_reviewed, :grade
      )
    end
  end

  describe ".type" do
    it "identifies as a gradable algorithm" do
      expect(described_class.type).to eq(:gradable)
    end
  end

  describe "upstream dependency boundary" do
    it "loads the upstream fsrs gem instead of a vendored internal copy" do
      expect(defined?(Fsrs::Scheduler)).to eq("constant")
      expect(ActiveRecall::FSRS.const_defined?(:Internal, false)).to be(false)
    end

    it "does not keep the vendored fsrs implementation in the repository" do
      vendored_path = File.expand_path(
        File.join("..", "..", "..", "lib", "active_recall", "algorithms", "fsrs", "internal.rb"),
        __dir__
      )

      expect(File.exist?(vendored_path)).to be(false)
    end
  end

  describe ".score" do
    context "grade validation" do
      it "raises when grade is below 1" do
        expect {
          described_class.score(**new_card_params.merge(grade: 0))
        }.to raise_error("Grade must be between 1-4!")
      end

      it "raises when grade is above 4" do
        expect {
          described_class.score(**new_card_params.merge(grade: 5))
        }.to raise_error("Grade must be between 1-4!")
      end

      [1, 2, 3, 4].each do |grade|
        it "accepts grade #{grade}" do
          expect {
            described_class.score(**new_card_params.merge(grade: grade))
          }.not_to raise_error
        end
      end
    end

    context "with a brand-new card (state: 0, no prior stability/difficulty)" do
      it "initializes stability and difficulty after the first review" do
        result = described_class.score(**new_card_params.merge(grade: 3))
        expect(result[:stability]).to be > 0
        expect(result[:difficulty]).to be_between(1, 10)
      end

      it "increments box (which maps to FSRS reps) to 1" do
        result = described_class.score(**new_card_params.merge(grade: 3))
        expect(result[:box]).to eq(1)
      end

      it "sets last_reviewed to current_time (in UTC)" do
        result = described_class.score(**new_card_params.merge(grade: 3))
        expect(result[:last_reviewed].to_time.utc).to eq(current_time)
      end

      it "transitions out of NEW state" do
        result = described_class.score(**new_card_params.merge(grade: 3))
        expect(result[:state]).not_to eq(0)
      end

      it "increments times_right on a correct rating (>= 2)" do
        result = described_class.score(**new_card_params.merge(grade: 3))
        expect(result[:times_right]).to eq(1)
        expect(result[:times_wrong]).to eq(0)
      end

      it "increments times_wrong on AGAIN (grade 1)" do
        result = described_class.score(**new_card_params.merge(grade: 1))
        expect(result[:times_right]).to eq(0)
        expect(result[:times_wrong]).to eq(1)
      end

      # Regression guard for ActiveRecall's expected behavior when delegating
      # new-card scheduling to the upstream fsrs gem.
      {1 => 1.minute, 2 => 5.minutes, 3 => 10.minutes}.each do |grade, expected_delta|
        it "schedules grade #{grade} on a new card #{expected_delta.inspect} out, not days" do
          result = described_class.score(**new_card_params.merge(grade: grade))
          delta_seconds = (result[:next_review].to_time.utc - current_time).to_i
          expect(delta_seconds).to eq(expected_delta.to_i)
        end
      end

      it "schedules grade 4 (Easy) on a new card on a days-scale interval" do
        result = described_class.score(**new_card_params.merge(grade: 4))
        delta_days = (result[:next_review].to_time.utc - current_time) / 86_400.0
        expect(delta_days).to be >= 1
        expect(delta_days).to be <= 30
      end
    end

    context "with an established REVIEW-state card" do
      let(:reviewed_card_params) do
        {
          box: 3,
          stability: 10.0,
          difficulty: 5.0,
          state: Fsrs::State::REVIEW,
          lapses: 0,
          elapsed_days: 10,
          scheduled_days: 10,
          times_right: 3,
          times_wrong: 0,
          last_reviewed: current_time - 10.days,
          current_time: current_time
        }
      end

      it "produces increasing intervals across grades AGAIN<HARD<GOOD<EASY (or equal at clamps)" do
        results = [1, 2, 3, 4].map do |grade|
          described_class.score(**reviewed_card_params.merge(grade: grade))
        end
        intervals = results.map { |r| r[:next_review] }
        expect(intervals[0]).to be <= intervals[1]
        expect(intervals[1]).to be <= intervals[2]
        expect(intervals[2]).to be <= intervals[3]
      end

      it "increments lapses when a REVIEW-state card is rated AGAIN" do
        result = described_class.score(**reviewed_card_params.merge(grade: 1))
        expect(result[:lapses]).to eq(1)
      end

      it "does not increment lapses on a passing grade" do
        result = described_class.score(**reviewed_card_params.merge(grade: 3))
        expect(result[:lapses]).to eq(0)
      end

      it "preserves times_right counter on AGAIN" do
        result = described_class.score(**reviewed_card_params.merge(grade: 1))
        expect(result[:times_right]).to eq(3)
        expect(result[:times_wrong]).to eq(1)
      end
    end

    context "configuration overrides" do
      let(:reviewed_card_params) do
        {
          box: 3,
          stability: 10.0,
          difficulty: 5.0,
          state: Fsrs::State::REVIEW,
          lapses: 0,
          elapsed_days: 10,
          scheduled_days: 10,
          times_right: 3,
          times_wrong: 0,
          last_reviewed: current_time - 10.days,
          current_time: current_time,
          grade: 3
        }
      end

      it "respects fsrs_request_retention (lower retention => longer intervals)" do
        baseline = described_class.score(**reviewed_card_params)

        ActiveRecall.configuration.fsrs_request_retention = 0.5
        relaxed = described_class.score(**reviewed_card_params)

        expect(relaxed[:scheduled_days]).to be > baseline[:scheduled_days]
      end

      it "respects fsrs_maximum_interval (clamps scheduled_days)" do
        baseline = described_class.score(**reviewed_card_params)

        ActiveRecall.configuration.fsrs_maximum_interval = 5
        capped = described_class.score(**reviewed_card_params)

        # +1 internal adjustment can push one over the cap; assert near-cap, not strict <=
        expect(capped[:scheduled_days]).to be < baseline[:scheduled_days]
        expect(capped[:scheduled_days]).to be <= 6
      end
    end

    context "with last_reviewed as an ActiveSupport::TimeWithZone" do
      it "still computes a result without raising" do
        Time.use_zone("Pacific Time (US & Canada)") do
          params = new_card_params.merge(
            last_reviewed: Time.current,
            current_time: Time.current,
            grade: 3
          )
          expect { described_class.score(**params) }.not_to raise_error
        end
      end
    end
  end
end
