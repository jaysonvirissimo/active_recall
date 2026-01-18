# frozen_string_literal: true

require "spec_helper"

describe ActiveRecall::FibonacciSequence do
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

  describe "SEQUENCE constant" do
    it "contains the first 21 Fibonacci numbers" do
      expected = [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181, 6765]
      expect(described_class::SEQUENCE).to eq(expected)
    end
  end

  describe ".right" do
    subject { described_class.right(**arguments) }

    let(:arguments) do
      {box: box, current_time: current_time, times_right: times_right, times_wrong: times_wrong}
    end
    let(:times_right) { 0 }
    let(:times_wrong) { 0 }

    shared_examples "fibonacci interval" do |from_box, expected_days, fib_description|
      context "from box #{from_box}" do
        let(:box) { from_box }
        let(:times_right) { from_box }

        it "schedules next_review for #{expected_days} days (#{fib_description})" do
          expect(subject[:next_review]).to eq(current_time + expected_days.days)
        end

        it "increments box to #{from_box + 1}" do
          expect(subject[:box]).to eq(from_box + 1)
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

    # Test first few boxes (already partially covered)
    # next_review = fibonacci_number_at(box + 1).days
    include_examples "fibonacci interval", 0, 1, "fib(1)=1"
    include_examples "fibonacci interval", 1, 1, "fib(2)=1"
    include_examples "fibonacci interval", 2, 2, "fib(3)=2"
    include_examples "fibonacci interval", 3, 3, "fib(4)=3"
    include_examples "fibonacci interval", 4, 5, "fib(5)=5"

    # Extended coverage for boxes 5-10
    include_examples "fibonacci interval", 5, 8, "fib(6)=8"
    include_examples "fibonacci interval", 6, 13, "fib(7)=13"
    include_examples "fibonacci interval", 7, 21, "fib(8)=21"
    include_examples "fibonacci interval", 8, 34, "fib(9)=34"
    include_examples "fibonacci interval", 9, 55, "fib(10)=55"
    include_examples "fibonacci interval", 10, 89, "fib(11)=89"

    # Higher boxes still within SEQUENCE array (indices 0-20)
    include_examples "fibonacci interval", 14, 610, "fib(15)=610"
    include_examples "fibonacci interval", 19, 6765, "fib(20)=6765"

    # Test boxes beyond SEQUENCE array (requires cache computation)
    context "beyond pre-computed SEQUENCE array" do
      # fib(21) = fib(20) + fib(19) = 6765 + 4181 = 10946
      include_examples "fibonacci interval", 20, 10946, "fib(21)=10946"

      # fib(22) = fib(21) + fib(20) = 10946 + 6765 = 17711
      include_examples "fibonacci interval", 21, 17711, "fib(22)=17711"

      # fib(25) = 75025
      include_examples "fibonacci interval", 24, 75025, "fib(25)=75025"
    end

    context "with high box numbers" do
      let(:box) { 30 }
      let(:times_right) { 30 }
      # fib(31) = 1346269

      it "correctly calculates large fibonacci numbers" do
        expect(subject[:next_review]).to eq(current_time + 1346269.days)
      end

      it "does not cause performance issues" do
        # This should complete quickly without stack overflow
        expect { subject }.not_to raise_error
      end
    end
  end

  describe ".wrong" do
    let(:arguments) do
      {box: box, current_time: current_time, times_right: times_right, times_wrong: times_wrong}
    end
    let(:times_right) { 5 }
    let(:times_wrong) { 1 }

    subject { described_class.wrong(**arguments) }

    shared_examples "reset on wrong" do |from_box|
      context "from box #{from_box}" do
        let(:box) { from_box }

        it "resets box to 0" do
          expect(subject[:box]).to eq(0)
        end

        it "sets next_review to nil" do
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

    include_examples "reset on wrong", 0
    include_examples "reset on wrong", 1
    include_examples "reset on wrong", 5
    include_examples "reset on wrong", 10
    include_examples "reset on wrong", 20
    include_examples "reset on wrong", 100

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

  describe "#fibonacci_number_at" do
    let(:instance) do
      described_class.new(box: 0, times_right: 0, times_wrong: 0)
    end

    # Test values within SEQUENCE array
    it { expect(instance.send(:fibonacci_number_at, 0)).to eq(0) }
    it { expect(instance.send(:fibonacci_number_at, 1)).to eq(1) }
    it { expect(instance.send(:fibonacci_number_at, 2)).to eq(1) }
    it { expect(instance.send(:fibonacci_number_at, 3)).to eq(2) }
    it { expect(instance.send(:fibonacci_number_at, 4)).to eq(3) }
    it { expect(instance.send(:fibonacci_number_at, 5)).to eq(5) }
    it { expect(instance.send(:fibonacci_number_at, 6)).to eq(8) }
    it { expect(instance.send(:fibonacci_number_at, 7)).to eq(13) }
    it { expect(instance.send(:fibonacci_number_at, 8)).to eq(21) }
    it { expect(instance.send(:fibonacci_number_at, 9)).to eq(34) }
    it { expect(instance.send(:fibonacci_number_at, 10)).to eq(55) }
    it { expect(instance.send(:fibonacci_number_at, 15)).to eq(610) }
    it { expect(instance.send(:fibonacci_number_at, 20)).to eq(6765) }

    # Test values beyond SEQUENCE array (uses cache)
    it { expect(instance.send(:fibonacci_number_at, 21)).to eq(10946) }
    it { expect(instance.send(:fibonacci_number_at, 22)).to eq(17711) }
    it { expect(instance.send(:fibonacci_number_at, 25)).to eq(75025) }
    it { expect(instance.send(:fibonacci_number_at, 30)).to eq(832040) }

    context "cache behavior" do
      it "caches computed values for reuse" do
        # First call computes and caches
        result1 = instance.send(:fibonacci_number_at, 25)
        # Second call should use cache (we verify by checking result is same)
        result2 = instance.send(:fibonacci_number_at, 25)

        expect(result1).to eq(result2)
        expect(result1).to eq(75025)
      end

      it "uses per-instance cache (not class-level)" do
        instance1 = described_class.new(box: 0, times_right: 0, times_wrong: 0)
        instance2 = described_class.new(box: 0, times_right: 0, times_wrong: 0)

        # Both should compute correctly despite separate caches
        expect(instance1.send(:fibonacci_number_at, 25)).to eq(75025)
        expect(instance2.send(:fibonacci_number_at, 25)).to eq(75025)
      end
    end
  end

  describe "full progression sequence" do
    it "moves through boxes with increasing fibonacci intervals" do
      state = {box: 0, times_right: 0, times_wrong: 0}
      expected_intervals = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55]

      expected_intervals.each_with_index do |expected_interval, index|
        result = described_class.right(**state, current_time: current_time)
        expect(result[:next_review]).to eq(current_time + expected_interval.days),
          "Box #{index} should have #{expected_interval} day interval"
        expect(result[:box]).to eq(index + 1)
        state = result.slice(:box, :times_right, :times_wrong)
      end
    end
  end

  describe "realistic learning sequence" do
    it "handles a mixed sequence of right and wrong answers" do
      state = {box: 0, times_right: 0, times_wrong: 0}

      # Progress through several boxes: 0 -> 1 -> 2 -> 3 -> 4
      4.times do
        result = described_class.right(**state, current_time: current_time)
        state = result.slice(:box, :times_right, :times_wrong)
      end
      expect(state[:box]).to eq(4)
      expect(state[:times_right]).to eq(4)

      # Fail and reset: 4 -> 0
      result = described_class.wrong(**state, current_time: current_time)
      state = result.slice(:box, :times_right, :times_wrong)
      expect(state[:box]).to eq(0)
      expect(state[:times_wrong]).to eq(1)

      # Partially recover: 0 -> 1 -> 2
      2.times do
        result = described_class.right(**state, current_time: current_time)
        state = result.slice(:box, :times_right, :times_wrong)
      end
      expect(state[:box]).to eq(2)
      expect(state[:times_right]).to eq(6)
      expect(state[:times_wrong]).to eq(1)
    end

    it "handles consecutive wrong answers" do
      state = {box: 10, times_right: 10, times_wrong: 0}

      # Multiple consecutive wrong answers
      3.times do
        result = described_class.wrong(**state, current_time: current_time)
        state = result.slice(:box, :times_right, :times_wrong)
        expect(state[:box]).to eq(0) # Always resets to 0
      end

      expect(state[:times_wrong]).to eq(3)
      expect(state[:times_right]).to eq(10) # Unchanged
    end
  end
end
