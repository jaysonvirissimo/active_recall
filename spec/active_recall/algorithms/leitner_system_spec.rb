# frozen_string_literal: true

require "spec_helper"

describe ActiveRecall::LeitnerSystem do
  it_behaves_like "binary spaced repetition algorithms"

  let(:current_time) { Time.current }

  describe ".required_attributes" do
    specify do
      expect(described_class.required_attributes).to contain_exactly(
        :box,
        :times_right,
        :times_wrong
      )
    end
  end

  describe ".type" do
    it "identifies as a binary algorithm" do
      expect(described_class.type).to eq(:binary)
    end
  end

  describe "DELAYS constant" do
    it "defines the correct delay schedule" do
      expect(described_class::DELAYS).to eq([3, 7, 14, 30, 60, 120, 240])
    end
  end

  describe ".right" do
    let(:params) do
      {
        box: box,
        times_right: times_right,
        times_wrong: times_wrong,
        current_time: current_time
      }
    end
    let(:times_right) { 3 }
    let(:times_wrong) { 1 }

    subject { described_class.right(**params) }

    shared_examples "correct right behavior" do |from_box, expected_delay|
      context "from box #{from_box}" do
        let(:box) { from_box }

        it "increments box to #{from_box + 1}" do
          expect(subject[:box]).to eq(from_box + 1)
        end

        it "sets next_review to #{expected_delay} days from now" do
          expect(subject[:next_review]).to eq(current_time + expected_delay.days)
        end

        it "increments times_right" do
          expect(subject[:times_right]).to eq(times_right + 1)
        end

        it "leaves times_wrong unchanged" do
          expect(subject[:times_wrong]).to eq(times_wrong)
        end

        it "sets last_reviewed to current_time" do
          expect(subject[:last_reviewed]).to eq(current_time)
        end
      end
    end

    # Test box progression with corresponding delay values
    # next_review = DELAYS[[DELAYS.count, box + 1].min - 1]
    include_examples "correct right behavior", 0, 3   # DELAYS[0]
    include_examples "correct right behavior", 1, 7   # DELAYS[1]
    include_examples "correct right behavior", 2, 14  # DELAYS[2]
    include_examples "correct right behavior", 3, 30  # DELAYS[3]
    include_examples "correct right behavior", 4, 60  # DELAYS[4]
    include_examples "correct right behavior", 5, 120 # DELAYS[5]
    include_examples "correct right behavior", 6, 240 # DELAYS[6]

    context "when at or beyond maximum delay index" do
      # For box >= 6, delay is capped at DELAYS[6] = 240
      include_examples "correct right behavior", 7, 240  # Capped at DELAYS[6]
      include_examples "correct right behavior", 10, 240 # Still capped
      include_examples "correct right behavior", 100, 240 # Very high box number
    end

    context "with initial counters at zero" do
      let(:times_right) { 0 }
      let(:times_wrong) { 0 }
      let(:box) { 0 }

      it "starts tracking correctly" do
        expect(subject[:times_right]).to eq(1)
        expect(subject[:times_wrong]).to eq(0)
      end
    end
  end

  describe ".wrong" do
    let(:params) do
      {
        box: box,
        times_right: times_right,
        times_wrong: times_wrong,
        current_time: current_time
      }
    end
    let(:times_right) { 5 }
    let(:times_wrong) { 2 }

    subject { described_class.wrong(**params) }

    shared_examples "correct wrong behavior" do |from_box|
      context "from box #{from_box}" do
        let(:box) { from_box }

        it "resets box to 0" do
          expect(subject[:box]).to eq(0)
        end

        it "sets next_review to nil (card needs immediate review)" do
          expect(subject[:next_review]).to be_nil
        end

        it "increments times_wrong" do
          expect(subject[:times_wrong]).to eq(times_wrong + 1)
        end

        it "leaves times_right unchanged" do
          expect(subject[:times_right]).to eq(times_right)
        end

        it "sets last_reviewed to current_time" do
          expect(subject[:last_reviewed]).to eq(current_time)
        end
      end
    end

    # Wrong always resets to box 0 regardless of current box
    include_examples "correct wrong behavior", 0
    include_examples "correct wrong behavior", 1
    include_examples "correct wrong behavior", 3
    include_examples "correct wrong behavior", 6
    include_examples "correct wrong behavior", 7
    include_examples "correct wrong behavior", 100

    context "with initial counters at zero" do
      let(:times_right) { 0 }
      let(:times_wrong) { 0 }
      let(:box) { 0 }

      it "starts tracking correctly" do
        expect(subject[:times_right]).to eq(0)
        expect(subject[:times_wrong]).to eq(1)
      end
    end
  end

  describe "full box progression" do
    it "moves through all boxes with consecutive right answers" do
      state = {box: 0, times_right: 0, times_wrong: 0}

      # Box 0 -> 1
      result = described_class.right(**state, current_time: current_time)
      expect(result[:box]).to eq(1)
      expect(result[:next_review]).to eq(current_time + 3.days)

      # Box 1 -> 2
      state = result.slice(:box, :times_right, :times_wrong)
      result = described_class.right(**state, current_time: current_time)
      expect(result[:box]).to eq(2)
      expect(result[:next_review]).to eq(current_time + 7.days)

      # Box 2 -> 3
      state = result.slice(:box, :times_right, :times_wrong)
      result = described_class.right(**state, current_time: current_time)
      expect(result[:box]).to eq(3)
      expect(result[:next_review]).to eq(current_time + 14.days)

      # Continue to box 7+
      state = result.slice(:box, :times_right, :times_wrong)
      4.times do
        result = described_class.right(**state, current_time: current_time)
        state = result.slice(:box, :times_right, :times_wrong)
      end

      expect(result[:box]).to eq(7)
      expect(result[:times_right]).to eq(7)
    end
  end

  describe "comparison with SoftLeitnerSystem" do
    let(:params) { {box: 2, times_right: 2, times_wrong: 0, current_time: current_time} }

    it "uses different delay calculation than SoftLeitnerSystem" do
      # LeitnerSystem: DELAYS[[DELAYS.count, box + 1].min - 1]
      # For box 2: DELAYS[[7, 3].min - 1] = DELAYS[2] = 14 days
      leitner_result = described_class.right(**params)
      expect(leitner_result[:next_review]).to eq(current_time + 14.days)

      # SoftLeitnerSystem: DELAYS[[DELAYS.count, box].min - 1] (uses new box value)
      # For box 2->3: DELAYS[[7, 3].min - 1] = DELAYS[2] = 14 days
      soft_result = ActiveRecall::SoftLeitnerSystem.right(**params)
      expect(soft_result[:next_review]).to eq(current_time + 14.days)

      # They differ in wrong behavior: LeitnerSystem sets next_review to nil
      leitner_wrong = described_class.wrong(**params)
      soft_wrong = ActiveRecall::SoftLeitnerSystem.wrong(**params)

      expect(leitner_wrong[:next_review]).to be_nil
      expect(soft_wrong[:next_review]).not_to be_nil
    end
  end

  describe "realistic learning sequence" do
    it "handles a mixed sequence of right and wrong answers" do
      state = {box: 0, times_right: 0, times_wrong: 0}

      # Learn well: 0 -> 1 -> 2 -> 3
      3.times do
        result = described_class.right(**state, current_time: current_time)
        state = result.slice(:box, :times_right, :times_wrong)
      end
      expect(state[:box]).to eq(3)
      expect(state[:times_right]).to eq(3)

      # Forget: 3 -> 0
      result = described_class.wrong(**state, current_time: current_time)
      state = result.slice(:box, :times_right, :times_wrong)
      expect(state[:box]).to eq(0)
      expect(state[:times_wrong]).to eq(1)

      # Relearn: 0 -> 1 -> 2
      2.times do
        result = described_class.right(**state, current_time: current_time)
        state = result.slice(:box, :times_right, :times_wrong)
      end
      expect(state[:box]).to eq(2)
      expect(state[:times_right]).to eq(5)
      expect(state[:times_wrong]).to eq(1)
    end
  end
end
