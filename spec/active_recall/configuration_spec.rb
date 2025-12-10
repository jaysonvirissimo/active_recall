# frozen_string_literal: true

require "spec_helper"

describe ActiveRecall::Configuration do
  subject { described_class.new }

  describe "#initialize" do
    it "sets the default algorithm_class to LeitnerSystem" do
      expect(subject.algorithm_class).to eq(ActiveRecall::LeitnerSystem)
    end
  end

  describe "#algorithm_class" do
    it "returns the configured algorithm class" do
      expect(subject.algorithm_class).to eq(ActiveRecall::LeitnerSystem)
    end
  end

  describe "#algorithm_class=" do
    context "when setting to FibonacciSequence" do
      it "updates the algorithm_class" do
        subject.algorithm_class = ActiveRecall::FibonacciSequence
        expect(subject.algorithm_class).to eq(ActiveRecall::FibonacciSequence)
      end
    end

    context "when setting to SM2" do
      it "updates the algorithm_class" do
        subject.algorithm_class = ActiveRecall::SM2
        expect(subject.algorithm_class).to eq(ActiveRecall::SM2)
      end
    end

    context "when setting to SoftLeitnerSystem" do
      it "updates the algorithm_class" do
        subject.algorithm_class = ActiveRecall::SoftLeitnerSystem
        expect(subject.algorithm_class).to eq(ActiveRecall::SoftLeitnerSystem)
      end
    end

    context "when setting back to LeitnerSystem" do
      it "updates the algorithm_class" do
        subject.algorithm_class = ActiveRecall::FibonacciSequence
        subject.algorithm_class = ActiveRecall::LeitnerSystem
        expect(subject.algorithm_class).to eq(ActiveRecall::LeitnerSystem)
      end
    end
  end

  context "multiple instances" do
    it "maintains independent algorithm_class values" do
      config1 = described_class.new
      config2 = described_class.new

      config1.algorithm_class = ActiveRecall::FibonacciSequence
      config2.algorithm_class = ActiveRecall::SM2

      expect(config1.algorithm_class).to eq(ActiveRecall::FibonacciSequence)
      expect(config2.algorithm_class).to eq(ActiveRecall::SM2)
    end

    it "does not affect other instances when modified" do
      config1 = described_class.new
      config2 = described_class.new

      config1.algorithm_class = ActiveRecall::FibonacciSequence

      expect(config2.algorithm_class).to eq(ActiveRecall::LeitnerSystem)
    end
  end
end
