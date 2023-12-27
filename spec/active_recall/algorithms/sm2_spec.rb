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

  describe ".score" do
    let(:params) do
      {
        box: 1,
        easiness_factor: 2.5,
        times_right: 2,
        times_wrong: 1,
        grade: 5,
        current_time: current_time
      }
    end

    subject { described_class.score(**params) }

    it "updates the box correctly" do
      expect(subject[:box]).to eq(2)
    end

    it "updates the easiness factor correctly" do
      expect(subject[:easiness_factor]).to be > 2.5
    end

    it "increments times right for a correct response" do
      expect(subject[:times_right]).to eq(3)
    end

    it "does not change times wrong for a correct response" do
      expect(subject[:times_wrong]).to eq(1)
    end

    it "sets the next review date based on the interval" do
      expect(subject[:next_review]).to eq(current_time + 6.days)
    end

    context "when the response is incorrect" do
      before { params[:grade] = 2 }

      it "resets the box to 0" do
        expect(subject[:box]).to eq(0)
      end

      it "increments times wrong" do
        expect(subject[:times_wrong]).to eq(2)
      end

      it "does not change times right" do
        expect(subject[:times_right]).to eq(2)
      end

      it "sets the next review date to the next day" do
        expect(subject[:next_review]).to eq(current_time + 1.day)
      end
    end

    context "with an impossible grade" do
      before { params[:grade] = 10 }

      specify do
        expect { subject }.to raise_error
      end
    end
  end
end
