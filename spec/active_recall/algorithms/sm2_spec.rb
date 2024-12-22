# frozen_string_literal: true

require "spec_helper"

describe ActiveRecall::SM2 do
  let(:current_time) { Time.current }

  describe ".required_attributes" do
    specify do
      expect(described_class.required_attributes).to contain_exactly(
        :box,
        :easiness_factor,
        :grade,
        :times_right,
        :times_wrong
      )
    end
  end

  describe ".type" do
    it "identifies as a gradable algorithm" do
      expect(described_class.type).to eq(:gradable)
    end
  end

  describe ".score" do
    subject { described_class.score(**params) }

    shared_examples "tracks attempts correctly" do
      it "updates times_right and times_wrong appropriately" do
        expect(subject[:times_right]).to eq(expected_times_right)
        expect(subject[:times_wrong]).to eq(expected_times_wrong)
      end
    end

    context "with an initial review" do
      let(:params) do
        {
          box: 0,
          easiness_factor: 2.5,
          times_right: 0,
          times_wrong: 0,
          grade: grade,
          current_time: current_time
        }
      end

      context "when the response is perfect (grade 5)" do
        let(:grade) { 5 }
        let(:expected_times_right) { 1 }
        let(:expected_times_wrong) { 0 }

        it "moves to box 1" do
          expect(subject[:box]).to eq(1)
        end

        it "increases the easiness factor" do
          expect(subject[:easiness_factor]).to be > 2.5
        end

        it "sets a one day interval" do
          expect(subject[:next_review]).to eq(current_time + 1.day)
        end

        include_examples "tracks attempts correctly"
      end

      context "when the response is poor (grade 2)" do
        let(:grade) { 2 }
        let(:expected_times_right) { 0 }
        let(:expected_times_wrong) { 1 }

        it "stays in box 0" do
          expect(subject[:box]).to eq(0)
        end

        it "decreases the easiness factor" do
          expect(subject[:easiness_factor]).to be < 2.5
          expect(subject[:easiness_factor]).to be >= described_class::MIN_EASINESS_FACTOR
        end

        it "sets a one day interval" do
          expect(subject[:next_review]).to eq(current_time + 1.day)
        end

        include_examples "tracks attempts correctly"
      end
    end

    context "with successive correct reviews" do
      let(:initial_params) do
        {
          box: 0,
          easiness_factor: 2.5,
          times_right: 0,
          times_wrong: 0,
          grade: 5,
          current_time: current_time
        }
      end

      it "follows the correct interval progression" do
        # First review
        result1 = described_class.score(**initial_params)
        expect(result1[:next_review]).to eq(current_time + 1.day)
        expect(result1[:box]).to eq(1)

        # Second review
        result2 = described_class.score(
          **result1.slice(:box, :easiness_factor, :times_right, :times_wrong).merge(
            grade: 5,
            current_time: result1[:next_review]
          )
        )
        expect(result2[:next_review]).to eq(result1[:next_review] + 6.days)
        expect(result2[:box]).to eq(2)

        # Third review - should be 6 * EF
        result3 = described_class.score(
          **result2.slice(:box, :easiness_factor, :times_right, :times_wrong).merge(
            grade: 5,
            current_time: result2[:next_review]
          )
        )
        expected_interval = (6 * result2[:easiness_factor]).round
        days_until_next_review = (result3[:next_review] - result2[:next_review]) / 1.day
        expect(days_until_next_review.to_i).to be_within(1).of(expected_interval)
        expect(result3[:box]).to eq(3)

        # Fourth review - should be previous_interval * EF
        result4 = described_class.score(
          **result3.slice(:box, :easiness_factor, :times_right, :times_wrong).merge(
            grade: 5,
            current_time: result3[:next_review]
          )
        )
        actual_prev_interval = (result3[:next_review] - result2[:next_review]) / 1.day
        # Allow for more variance in longer intervals - using 5% margin
        expected_interval = (actual_prev_interval.to_i * result3[:easiness_factor]).round
        days_until_next_review = (result4[:next_review] - result3[:next_review]) / 1.day
        margin = (expected_interval * 0.05).ceil # 5% margin, rounded up
        expect(days_until_next_review.to_i).to be_within(margin).of(expected_interval)
        expect(result4[:box]).to eq(4)
      end
    end

    context "with alternating good and poor performance" do
      let(:initial_params) do
        {
          box: 0,
          easiness_factor: 2.5,
          times_right: 0,
          times_wrong: 0,
          grade: 5,
          current_time: current_time
        }
      end

      it "resets progress appropriately on poor performance" do
        # First review - good
        result1 = described_class.score(**initial_params)
        expect(result1[:box]).to eq(1)

        # Second review - poor
        result2 = described_class.score(
          **result1.slice(:box, :easiness_factor, :times_right, :times_wrong).merge(
            grade: 2,
            current_time: result1[:next_review]
          )
        )
        expect(result2[:box]).to eq(0)
        expect(result2[:next_review]).to eq(result1[:next_review] + 1.day)

        # Third review - good again
        result3 = described_class.score(
          **result2.slice(:box, :easiness_factor, :times_right, :times_wrong).merge(
            grade: 5,
            current_time: result2[:next_review]
          )
        )
        expect(result3[:box]).to eq(1)
        expect(result3[:next_review]).to eq(result2[:next_review] + 1.day)
      end

      it "tracks attempts correctly" do
        # First review - good
        result1 = described_class.score(**initial_params)
        expect(result1[:times_right]).to eq(1)
        expect(result1[:times_wrong]).to eq(0)

        # Second review - poor
        result2 = described_class.score(
          **result1.slice(:box, :easiness_factor, :times_right, :times_wrong).merge(
            grade: 2,
            current_time: result1[:next_review]
          )
        )
        expect(result2[:times_right]).to eq(1)
        expect(result2[:times_wrong]).to eq(1)

        # Third review - good again
        result3 = described_class.score(
          **result2.slice(:box, :easiness_factor, :times_right, :times_wrong).merge(
            grade: 5,
            current_time: result2[:next_review]
          )
        )
        expect(result3[:times_right]).to eq(2)
        expect(result3[:times_wrong]).to eq(1)
      end

      it "adjusts easiness factor appropriately" do
        # First review - good
        result1 = described_class.score(**initial_params)
        ef1 = result1[:easiness_factor]
        expect(ef1).to be > 2.5

        # Second review - poor
        result2 = described_class.score(
          **result1.slice(:box, :easiness_factor, :times_right, :times_wrong).merge(
            grade: 2,
            current_time: result1[:next_review]
          )
        )
        ef2 = result2[:easiness_factor]
        expect(ef2).to be < ef1
        expect(ef2).to be >= described_class::MIN_EASINESS_FACTOR

        # Third review - good again
        result3 = described_class.score(
          **result2.slice(:box, :easiness_factor, :times_right, :times_wrong).merge(
            grade: 5,
            current_time: result2[:next_review]
          )
        )
        expect(result3[:easiness_factor]).to be > ef2
      end
    end

    context "with invalid inputs" do
      let(:params) do
        {
          box: 1,
          easiness_factor: 2.5,
          times_right: 2,
          times_wrong: 1,
          grade: grade,
          current_time: current_time
        }
      end

      context "with a grade below 0" do
        let(:grade) { -1 }
        it "raises an error" do
          expect { subject }.to raise_error("Grade must be between 0-5!")
        end
      end

      context "with a grade above 5" do
        let(:grade) { 6 }
        it "raises an error" do
          expect { subject }.to raise_error("Grade must be between 0-5!")
        end
      end

      context "with a nil grade" do
        let(:grade) { nil }
        it "raises an error" do
          expect { subject }.to raise_error("Grade must be between 0-5!")
        end
      end
    end
  end
end
