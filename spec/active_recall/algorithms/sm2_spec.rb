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

    context "with higher box values" do
      let(:params) do
        {
          box: box,
          easiness_factor: 2.46,
          times_right: 7,
          times_wrong: 0,
          grade: 5,
          current_time: current_time
        }
      end

      context "for box 7" do
        let(:box) { 7 }
        let(:expected_interval) { (6 * (2.46**6)).round }

        it "calculates a longer interval for a well-known card" do
          tolerance = (expected_interval * 0.005).ceil # 0.5% margin
          days_until_next_review = (subject[:next_review] - current_time) / 1.day
          expect(days_until_next_review.to_i).to be_within(tolerance).of(expected_interval)
        end

        it "increments the box correctly" do
          expect(subject[:box]).to eq(8)
        end
      end

      context "for box 5" do
        let(:box) { 5 }
        let(:expected_interval) { (6 * (2.46**4)).round }

        it "calculates the correct interval for a moderately known card" do
          tolerance = (expected_interval * 0.005).ceil # 0.5% margin
          days_until_next_review = (subject[:next_review] - current_time) / 1.day
          expect(days_until_next_review.to_i).to be_within(tolerance).of(expected_interval)
        end

        it "increments the box correctly" do
          expect(subject[:box]).to eq(6)
        end
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
