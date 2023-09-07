# frozen_string_literal: true

require "spec_helper"

describe ActiveRecall::SoftLeitnerSystem do
  it_behaves_like "spaced repetition algorithms"

  let(:current_time) { Time.current }

  describe ".right" do
    let(:params) do
      {
        box: 2,
        times_right: 3,
        times_wrong: 1,
        current_time: current_time
      }
    end

    subject { described_class.right(**params) }

    it "increments the box" do
      expect(subject[:box]).to eq(3)
    end

    it "increments times right" do
      expect(subject[:times_right]).to eq(4)
    end

    it "leaves times wrong alone" do
      expect(subject[:times_wrong]).to eq(1)
    end

    it "sets next review based on the incremented box" do
      expect(subject[:next_review]).to eq(current_time + described_class::DELAYS[2].days)
    end

    context "when starting from the maximum box" do
      it "stays in largest box" do
        params[:box] = 7
        expect(described_class.right(**params)[:box]).to eq(7)
      end
    end
  end

  describe ".wrong" do
    let(:params) do
      {
        box: 2,
        times_right: 3,
        times_wrong: 1,
        current_time: current_time
      }
    end

    subject { described_class.wrong(**params) }

    it "decrements the box" do
      expect(subject[:box]).to eq(1)
    end

    it "increments times wrong" do
      expect(subject[:times_wrong]).to eq(2)
    end

    it "leaves times right alone" do
      expect(subject[:times_right]).to eq(3)
    end

    it "sets the next review based on the decremented box" do
      expect(subject[:next_review]).to eq(current_time + described_class::DELAYS[0].days)
    end

    context "when already in box zero" do
      it "stays in box zero" do
        params[:box] = 0
        expect(described_class.wrong(**params)[:box]).to be_zero
      end
    end
  end
end
