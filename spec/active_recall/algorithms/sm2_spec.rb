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
        :times_wrong,
        :last_reviewed,
        :next_review
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

    shared_examples "sets last_reviewed to current time" do
      it "sets last_reviewed" do
        expect(subject[:last_reviewed]).to eq(current_time)
      end
    end

    context "with an initial review (box 0)" do
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

        it "increases the easiness factor by 0.10" do
          # EF formula: EF + (0.1 - (5-q)*(0.08 + (5-q)*0.02))
          # For grade 5: EF + (0.1 - 0*(0.08 + 0*0.02)) = EF + 0.1
          expect(subject[:easiness_factor]).to eq(2.6)
        end

        it "sets a one day interval (canonical SM2 I(1)=1)" do
          expect(subject[:next_review]).to eq(current_time + 1.day)
        end

        include_examples "tracks attempts correctly"
        include_examples "sets last_reviewed to current time"
      end

      context "when correct with hesitation (grade 4)" do
        let(:grade) { 4 }
        let(:expected_times_right) { 1 }
        let(:expected_times_wrong) { 0 }

        it "moves to box 1" do
          expect(subject[:box]).to eq(1)
        end

        it "keeps the easiness factor unchanged" do
          # For grade 4: EF + (0.1 - 1*(0.08 + 1*0.02)) = EF + (0.1 - 0.1) = EF + 0
          expect(subject[:easiness_factor]).to eq(2.5)
        end

        it "sets a one day interval" do
          expect(subject[:next_review]).to eq(current_time + 1.day)
        end

        include_examples "tracks attempts correctly"
        include_examples "sets last_reviewed to current time"
      end

      context "when correct with serious difficulty (grade 3)" do
        let(:grade) { 3 }
        let(:expected_times_right) { 1 }
        let(:expected_times_wrong) { 0 }

        it "moves to box 1" do
          expect(subject[:box]).to eq(1)
        end

        it "decreases the easiness factor by 0.14" do
          # For grade 3: EF + (0.1 - 2*(0.08 + 2*0.02)) = EF + (0.1 - 2*0.12) = EF - 0.14
          expect(subject[:easiness_factor]).to eq(2.36)
        end

        it "sets a one day interval" do
          expect(subject[:next_review]).to eq(current_time + 1.day)
        end

        include_examples "tracks attempts correctly"
        include_examples "sets last_reviewed to current time"
      end

      context "when incorrect but close (grade 2)" do
        let(:grade) { 2 }
        let(:expected_times_right) { 0 }
        let(:expected_times_wrong) { 1 }

        it "stays in box 0 (resets)" do
          expect(subject[:box]).to eq(0)
        end

        it "lowers the easiness factor by 0.32" do
          # Canonical SM2 updates EF on every grade. Grade 2: 2.5 - 0.32 = 2.18
          expect(subject[:easiness_factor]).to be_within(0.0001).of(2.18)
        end

        it "sets a one day interval" do
          expect(subject[:next_review]).to eq(current_time + 1.day)
        end

        include_examples "tracks attempts correctly"
        include_examples "sets last_reviewed to current time"
      end

      context "when incorrect with some familiarity (grade 1)" do
        let(:grade) { 1 }
        let(:expected_times_right) { 0 }
        let(:expected_times_wrong) { 1 }

        it "stays in box 0 (resets)" do
          expect(subject[:box]).to eq(0)
        end

        it "lowers the easiness factor by 0.54" do
          # Grade 1: 2.5 - 0.54 = 1.96
          expect(subject[:easiness_factor]).to be_within(0.0001).of(1.96)
        end

        it "sets a one day interval" do
          expect(subject[:next_review]).to eq(current_time + 1.day)
        end

        include_examples "tracks attempts correctly"
        include_examples "sets last_reviewed to current time"
      end

      context "when complete blackout (grade 0)" do
        let(:grade) { 0 }
        let(:expected_times_right) { 0 }
        let(:expected_times_wrong) { 1 }

        it "stays in box 0 (resets)" do
          expect(subject[:box]).to eq(0)
        end

        it "lowers the easiness factor by 0.80" do
          # Grade 0: 2.5 - 0.80 = 1.70
          expect(subject[:easiness_factor]).to be_within(0.0001).of(1.70)
        end

        it "sets a one day interval" do
          expect(subject[:next_review]).to eq(current_time + 1.day)
        end

        include_examples "tracks attempts correctly"
        include_examples "sets last_reviewed to current time"
      end
    end

    context "with box 1 (second review)" do
      let(:params) do
        {
          box: 1,
          easiness_factor: 2.5,
          times_right: 1,
          times_wrong: 0,
          grade: grade,
          current_time: current_time
        }
      end

      context "when successful (grade 5)" do
        let(:grade) { 5 }

        it "moves to box 2" do
          expect(subject[:box]).to eq(2)
        end

        it "sets a six day interval (canonical SM2 I(2)=6)" do
          expect(subject[:next_review]).to eq(current_time + 6.days)
        end
      end

      context "when failed (grade 2)" do
        let(:grade) { 2 }

        it "resets to box 0" do
          expect(subject[:box]).to eq(0)
        end

        it "lowers the easiness factor by 0.32" do
          # Grade 2: 2.5 - 0.32 = 2.18
          expect(subject[:easiness_factor]).to be_within(0.0001).of(2.18)
        end

        it "sets a one day interval" do
          expect(subject[:next_review]).to eq(current_time + 1.day)
        end
      end
    end

    context "with higher box values (interval recurrence)" do
      # Canonical SM2 recurrence: I(n) = round(I(n-1) * EF), where the prior
      # interval is recovered from the card's stored last_reviewed/next_review
      # and EF is the value from before this review's update.
      def params_for(box:, easiness_factor:, previous_interval:, grade: 5)
        {
          box: box,
          easiness_factor: easiness_factor,
          times_right: box,
          times_wrong: 0,
          grade: grade,
          last_reviewed: current_time,
          next_review: current_time + previous_interval.days,
          current_time: current_time
        }
      end

      context "for box 2 with grade 5 and a prior 6-day interval" do
        let(:params) { params_for(box: 2, easiness_factor: 2.5, previous_interval: 6) }

        it "moves to box 3" do
          expect(subject[:box]).to eq(3)
        end

        it "schedules round(6 * 2.5) = 15 days" do
          expect(subject[:next_review]).to eq(current_time + 15.days)
        end
      end

      context "for box 3 with grade 5 and a prior 16-day interval" do
        let(:params) { params_for(box: 3, easiness_factor: 2.7, previous_interval: 16) }

        it "moves to box 4" do
          expect(subject[:box]).to eq(4)
        end

        it "schedules round(16 * 2.7) = 43 days" do
          expect(subject[:next_review]).to eq(current_time + 43.days)
        end
      end

      context "with the minimum easiness factor and a prior 17-day interval" do
        let(:params) { params_for(box: 5, easiness_factor: 1.3, previous_interval: 17) }

        it "schedules a shorter interval round(17 * 1.3) = 22 days" do
          expect(subject[:next_review]).to eq(current_time + 22.days)
        end
      end

      context "when the prior schedule is unavailable" do
        let(:params) do
          {
            box: 5,
            easiness_factor: 2.5,
            times_right: 5,
            times_wrong: 0,
            grade: 5,
            current_time: current_time
          }
        end

        it "falls back to the I(2)=6 prior interval, scheduling round(6 * 2.5) = 15 days" do
          expect(subject[:next_review]).to eq(current_time + 15.days)
        end
      end
    end

    context "across a sequence of consecutive perfect reviews" do
      it "reproduces the published SM2 interval sequence (1, 6, 16, 45, 131, 393)" do
        expected_intervals = [1, 6, 16, 45, 131, 393]
        actual_intervals = []

        state = {box: 0, easiness_factor: 2.5, times_right: 0, times_wrong: 0}
        last_reviewed = nil
        next_review = nil
        review_time = current_time

        expected_intervals.each do
          result = described_class.score(
            **state,
            grade: 5,
            last_reviewed: last_reviewed,
            next_review: next_review,
            current_time: review_time
          )

          interval = ((result[:next_review] - review_time) / 1.day).round
          actual_intervals << interval

          state = result.slice(:box, :easiness_factor, :times_right, :times_wrong)
          last_reviewed = result[:last_reviewed]
          next_review = result[:next_review]
          review_time = result[:next_review]
        end

        expect(actual_intervals).to eq(expected_intervals)
      end
    end

    context "easiness factor boundaries" do
      context "when EF would drop below minimum" do
        let(:params) do
          {
            box: 5,
            easiness_factor: 1.4,
            times_right: 5,
            times_wrong: 0,
            grade: 3,
            current_time: current_time
          }
        end

        it "enforces MIN_EASINESS_FACTOR of 1.3" do
          # Grade 3 decreases EF by 0.14, so 1.4 - 0.14 = 1.26
          # But MIN is 1.3
          expect(subject[:easiness_factor]).to eq(described_class::MIN_EASINESS_FACTOR)
        end
      end

      context "when EF grows with consecutive perfect responses" do
        it "increases without upper bound" do
          ef = 2.5
          10.times do
            result = described_class.score(
              box: 5,
              easiness_factor: ef,
              times_right: 5,
              times_wrong: 0,
              grade: 5,
              current_time: current_time
            )
            ef = result[:easiness_factor]
          end
          # After 10 perfect responses: 2.5 + (10 * 0.1) = 3.5
          expect(ef).to be_within(0.0001).of(3.5)
        end
      end
    end

    context "with nil easiness_factor" do
      let(:params) do
        {
          box: 0,
          easiness_factor: nil,
          times_right: 0,
          times_wrong: 0,
          grade: 5,
          current_time: current_time
        }
      end

      it "defaults to 2.5" do
        # Initial EF of 2.5, grade 5 adds 0.1
        expect(subject[:easiness_factor]).to eq(2.6)
      end
    end

    context "canonical SM2 EF formula verification" do
      let(:initial_ef) { 2.5 }
      let(:params) do
        {
          box: 2,
          easiness_factor: initial_ef,
          times_right: 2,
          times_wrong: 0,
          grade: grade,
          current_time: current_time
        }
      end

      # EF' = EF + (0.1 - (5-q)*(0.08 + (5-q)*0.02))
      context "grade 5 (perfect)" do
        let(:grade) { 5 }
        it "adds 0.10 to EF" do
          expect(subject[:easiness_factor]).to eq(2.6)
        end
      end

      context "grade 4 (correct with hesitation)" do
        let(:grade) { 4 }
        it "adds 0.00 to EF (unchanged)" do
          expect(subject[:easiness_factor]).to eq(2.5)
        end
      end

      context "grade 3 (correct with difficulty)" do
        let(:grade) { 3 }
        it "subtracts 0.14 from EF" do
          expect(subject[:easiness_factor]).to eq(2.36)
        end
      end

      context "grades 0-2 (failures)" do
        # EF is updated on every grade, including failures (canonical SM2).
        {0 => 1.70, 1 => 1.96, 2 => 2.18}.each do |failing_grade, expected_ef|
          context "grade #{failing_grade}" do
            let(:grade) { failing_grade }
            it "updates EF to #{expected_ef}" do
              expect(subject[:easiness_factor]).to be_within(0.0001).of(expected_ef)
            end

            it "resets box to 0" do
              expect(subject[:box]).to eq(0)
            end
          end
        end
      end
    end

    context "realistic learning sequences" do
      it "handles a mixed sequence of successes and failures" do
        state = {
          box: 0,
          easiness_factor: 2.5,
          times_right: 0,
          times_wrong: 0
        }

        # First review: perfect
        result = described_class.score(**state, grade: 5, current_time: current_time)
        expect(result[:box]).to eq(1)
        expect(result[:easiness_factor]).to eq(2.6)
        expect(result[:times_right]).to eq(1)

        # Second review: failed
        state = result.slice(:box, :easiness_factor, :times_right, :times_wrong)
        result = described_class.score(**state, grade: 2, current_time: current_time + 1.day)
        expect(result[:box]).to eq(0)
        expect(result[:easiness_factor]).to be_within(0.0001).of(2.28) # 2.6 - 0.32 on failure
        expect(result[:times_wrong]).to eq(1)

        # Third review: perfect
        state = result.slice(:box, :easiness_factor, :times_right, :times_wrong)
        result = described_class.score(**state, grade: 5, current_time: current_time + 2.days)
        expect(result[:box]).to eq(1)
        expect(result[:easiness_factor]).to be_within(0.0001).of(2.38) # 2.28 + 0.10
        expect(result[:times_right]).to eq(2)
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
