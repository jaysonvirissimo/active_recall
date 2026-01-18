# frozen_string_literal: true

require "spec_helper"

describe ActiveRecall::SoftLeitnerSystem do
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

    shared_examples "soft right behavior" do |from_box, to_box, expected_delay|
      context "from box #{from_box}" do
        let(:box) { from_box }

        it "moves to box #{to_box}" do
          expect(subject[:box]).to eq(to_box)
        end

        it "sets next_review to #{expected_delay} days" do
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

    # Box progression with delays
    # Uses DELAYS[[DELAYS.count, new_box].min - 1]
    include_examples "soft right behavior", 0, 1, 3   # DELAYS[0]
    include_examples "soft right behavior", 1, 2, 7   # DELAYS[1]
    include_examples "soft right behavior", 2, 3, 14  # DELAYS[2]
    include_examples "soft right behavior", 3, 4, 30  # DELAYS[3]
    include_examples "soft right behavior", 4, 5, 60  # DELAYS[4]
    include_examples "soft right behavior", 5, 6, 120 # DELAYS[5]
    include_examples "soft right behavior", 6, 7, 240 # DELAYS[6]

    context "at maximum box" do
      # Box is capped at DELAYS.count (7)
      include_examples "soft right behavior", 7, 7, 240

      it "stays at maximum box even with many right answers" do
        max_box_params = {box: 7, times_right: 3, times_wrong: 1, current_time: current_time}
        result = described_class.right(**max_box_params)
        expect(result[:box]).to eq(7)

        # Chain another right
        result2 = described_class.right(
          box: result[:box],
          times_right: result[:times_right],
          times_wrong: result[:times_wrong],
          current_time: current_time
        )
        expect(result2[:box]).to eq(7)
      end
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

    shared_examples "soft wrong behavior" do |from_box, to_box, expected_delay|
      context "from box #{from_box}" do
        let(:box) { from_box }

        it "moves to box #{to_box}" do
          expect(subject[:box]).to eq(to_box)
        end

        it "sets next_review to #{expected_delay} days" do
          expect(subject[:next_review]).to eq(current_time + expected_delay.days)
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

    # Box regression with delays (decrements by 1 each time, minimum 0)
    # Note: When box becomes 0, DELAYS[[7, 0].min - 1] = DELAYS[-1] = 240
    # This is a quirk of the implementation where box 0 wraps to the longest delay
    include_examples "soft wrong behavior", 7, 6, 120 # DELAYS[5]
    include_examples "soft wrong behavior", 6, 5, 60  # DELAYS[4]
    include_examples "soft wrong behavior", 5, 4, 30  # DELAYS[3]
    include_examples "soft wrong behavior", 4, 3, 14  # DELAYS[2]
    include_examples "soft wrong behavior", 3, 2, 7   # DELAYS[1]
    include_examples "soft wrong behavior", 2, 1, 3   # DELAYS[0]
    include_examples "soft wrong behavior", 1, 0, 240 # DELAYS[-1] = 240 (wraps)

    context "at box 0" do
      let(:box) { 0 }

      it "stays at box 0" do
        expect(subject[:box]).to eq(0)
      end

      # Note: Box 0 results in DELAYS[-1] = 240 due to index calculation
      # This is a quirk of the implementation
      it "sets next_review based on DELAYS[-1] index wrap" do
        expect(subject[:next_review]).to eq(current_time + 240.days)
      end

      it "stays at box 0 with consecutive wrong answers" do
        result = described_class.wrong(**params)
        expect(result[:box]).to eq(0)

        result2 = described_class.wrong(
          box: result[:box],
          times_right: result[:times_right],
          times_wrong: result[:times_wrong],
          current_time: current_time
        )
        expect(result2[:box]).to eq(0)
        expect(result2[:times_wrong]).to eq(times_wrong + 2)
      end
    end

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
    it "moves through all boxes (0 to 7) with consecutive right answers" do
      state = {box: 0, times_right: 0, times_wrong: 0}
      expected_delays = [3, 7, 14, 30, 60, 120, 240]

      7.times do |i|
        result = described_class.right(**state, current_time: current_time)
        expect(result[:box]).to eq(i + 1)
        expect(result[:next_review]).to eq(current_time + expected_delays[i].days)
        state = result.slice(:box, :times_right, :times_wrong)
      end

      expect(state[:box]).to eq(7)
      expect(state[:times_right]).to eq(7)
    end
  end

  describe "full box regression" do
    it "moves back through all boxes (7 to 0) with consecutive wrong answers" do
      state = {box: 7, times_right: 7, times_wrong: 0}
      expected_delays = [120, 60, 30, 14, 7, 3, 240] # Last one wraps to DELAYS[-1]

      7.times do |i|
        result = described_class.wrong(**state, current_time: current_time)
        expect(result[:box]).to eq(6 - i)
        expect(result[:next_review]).to eq(current_time + expected_delays[i].days)
        state = result.slice(:box, :times_right, :times_wrong)
      end

      expect(state[:box]).to eq(0)
      expect(state[:times_wrong]).to eq(7)
    end
  end

  describe "comparison with LeitnerSystem" do
    let(:params) { {box: 3, times_right: 3, times_wrong: 1, current_time: current_time} }

    context "on wrong answer" do
      it "decrements box by 1 (soft) instead of resetting to 0 (hard)" do
        soft_result = described_class.wrong(**params)
        hard_result = ActiveRecall::LeitnerSystem.wrong(**params)

        expect(soft_result[:box]).to eq(2)  # Decremented by 1
        expect(hard_result[:box]).to eq(0)  # Reset to 0
      end

      it "keeps a review schedule (soft) instead of nil (hard)" do
        soft_result = described_class.wrong(**params)
        hard_result = ActiveRecall::LeitnerSystem.wrong(**params)

        expect(soft_result[:next_review]).not_to be_nil
        expect(hard_result[:next_review]).to be_nil
      end
    end

    context "on right answer" do
      it "caps box at DELAYS.count (7)" do
        params[:box] = 7
        soft_result = described_class.right(**params)
        hard_result = ActiveRecall::LeitnerSystem.right(**params)

        expect(soft_result[:box]).to eq(7)  # Capped
        expect(hard_result[:box]).to eq(8)  # No cap
      end
    end
  end

  describe "realistic learning sequence" do
    it "handles gradual forgetting and recovery" do
      state = {box: 0, times_right: 0, times_wrong: 0}

      # Learn well: 0 -> 1 -> 2 -> 3 -> 4
      4.times do
        result = described_class.right(**state, current_time: current_time)
        state = result.slice(:box, :times_right, :times_wrong)
      end
      expect(state[:box]).to eq(4)

      # Partially forget: 4 -> 3 -> 2
      2.times do
        result = described_class.wrong(**state, current_time: current_time)
        state = result.slice(:box, :times_right, :times_wrong)
      end
      expect(state[:box]).to eq(2)
      expect(state[:times_wrong]).to eq(2)

      # Recover: 2 -> 3 -> 4 -> 5
      3.times do
        result = described_class.right(**state, current_time: current_time)
        state = result.slice(:box, :times_right, :times_wrong)
      end
      expect(state[:box]).to eq(5)
      expect(state[:times_right]).to eq(7)
    end

    it "demonstrates the soft penalty at low boxes" do
      # Start at box 2
      state = {box: 2, times_right: 2, times_wrong: 0}

      # Wrong: 2 -> 1
      result = described_class.wrong(**state, current_time: current_time)
      expect(result[:box]).to eq(1)
      expect(result[:next_review]).to eq(current_time + 3.days)
      state = result.slice(:box, :times_right, :times_wrong)

      # Wrong: 1 -> 0 (with DELAYS[-1] quirk)
      result = described_class.wrong(**state, current_time: current_time)
      expect(result[:box]).to eq(0)
      expect(result[:next_review]).to eq(current_time + 240.days)
      state = result.slice(:box, :times_right, :times_wrong)

      # Right: 0 -> 1 (normal behavior resumes)
      result = described_class.right(**state, current_time: current_time)
      expect(result[:box]).to eq(1)
      expect(result[:next_review]).to eq(current_time + 3.days)
    end
  end
end
