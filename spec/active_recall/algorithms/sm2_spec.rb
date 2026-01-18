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

        it "preserves the easiness factor (canonical SM2 behavior)" do
          # Per canonical SM2: "start repetitions from beginning WITHOUT changing the E-Factor"
          expect(subject[:easiness_factor]).to eq(2.5)
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

        it "preserves the easiness factor (canonical SM2 behavior)" do
          expect(subject[:easiness_factor]).to eq(2.5)
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

        it "preserves the easiness factor (canonical SM2 behavior)" do
          expect(subject[:easiness_factor]).to eq(2.5)
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

        it "preserves the easiness factor" do
          expect(subject[:easiness_factor]).to eq(2.5)
        end

        it "sets a one day interval" do
          expect(subject[:next_review]).to eq(current_time + 1.day)
        end
      end
    end

    context "with higher box values (exponential interval)" do
      let(:params) do
        {
          box: box,
          easiness_factor: 2.5,
          times_right: box,
          times_wrong: 0,
          grade: grade,
          current_time: current_time
        }
      end

      context "for box 2 with grade 5" do
        let(:box) { 2 }
        let(:grade) { 5 }

        it "moves to box 3" do
          expect(subject[:box]).to eq(3)
        end

        it "calculates interval as 6 * EF^(box-1) = 6 * 2.5^1 = 15 days" do
          # Note: interval uses old_ef (2.5) before the EF update
          expect(subject[:next_review]).to eq(current_time + 15.days)
        end
      end

      context "for box 3 with grade 5" do
        let(:box) { 3 }
        let(:grade) { 5 }

        it "moves to box 4" do
          expect(subject[:box]).to eq(4)
        end

        it "calculates interval as 6 * EF^(box-1) = 6 * 2.5^2 = 38 days (rounded)" do
          expect(subject[:next_review]).to eq(current_time + 38.days)
        end
      end

      context "for box 7 with grade 5" do
        let(:box) { 7 }
        let(:grade) { 5 }
        let(:expected_interval) { (6 * (2.5**6)).round }

        it "calculates the correct exponential interval" do
          days_until_next_review = ((subject[:next_review] - current_time) / 1.day).round
          expect(days_until_next_review).to eq(expected_interval)
        end

        it "increments the box correctly" do
          expect(subject[:box]).to eq(8)
        end
      end

      context "for box 5 with varying easiness factors" do
        let(:box) { 5 }
        let(:grade) { 5 }

        context "with EF 2.5" do
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

          it "calculates interval as 6 * 2.5^4 = 234 days (rounded)" do
            expect(subject[:next_review]).to eq(current_time + 234.days)
          end
        end

        context "with EF 1.3 (minimum)" do
          let(:params) do
            {
              box: 5,
              easiness_factor: 1.3,
              times_right: 5,
              times_wrong: 0,
              grade: 5,
              current_time: current_time
            }
          end

          it "calculates a shorter interval" do
            # 6 * 1.3^4 = 17.15 ≈ 17 days
            expect(subject[:next_review]).to eq(current_time + 17.days)
          end
        end
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
        [0, 1, 2].each do |failing_grade|
          context "grade #{failing_grade}" do
            let(:grade) { failing_grade }
            it "preserves EF (canonical SM2: don't change EF on failure)" do
              expect(subject[:easiness_factor]).to eq(initial_ef)
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
        expect(result[:easiness_factor]).to eq(2.6) # EF preserved on failure
        expect(result[:times_wrong]).to eq(1)

        # Third review: perfect
        state = result.slice(:box, :easiness_factor, :times_right, :times_wrong)
        result = described_class.score(**state, grade: 5, current_time: current_time + 2.days)
        expect(result[:box]).to eq(1)
        expect(result[:easiness_factor]).to eq(2.7)
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
