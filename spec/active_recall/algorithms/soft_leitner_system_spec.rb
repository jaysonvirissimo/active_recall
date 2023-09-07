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

    it "increments the box by 1" do
      expect(subject[:box]).to eq(params[:box] + 1)
    end

    it "increments times_right by 1" do
      expect(subject[:times_right]).to eq(params[:times_right] + 1)
    end

    it "does not change times_wrong" do
      expect(subject[:times_wrong]).to eq(params[:times_wrong])
    end

    it "sets next_review based on delays" do
      expect(subject[:next_review]).to eq(current_time + described_class::DELAYS[params[:box]].days)
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

    it "decrements the box by 1 but not below 0" do
      expect(subject[:box]).to eq([params[:box] - 1, 0].max)
    end

    it "increments times_wrong by 1" do
      expect(subject[:times_wrong]).to eq(params[:times_wrong] + 1)
    end

    it "does not change times_right" do
      expect(subject[:times_right]).to eq(params[:times_right])
    end
  end
end
