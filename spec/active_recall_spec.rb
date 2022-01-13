# frozen_string_literal: true

require "spec_helper"

describe ActiveRecall do
  let(:user) { User.create!(name: "Jayson") }
  let(:word) do
    Word.create!(
      kanji: "日本語",
      kana: "にほんご",
      translation: "Japanese language"
    )
  end

  describe "#configure" do
    before { user.words << word }
    after { described_class.reset }

    context "by default" do
      it "uses the Leitner system algorithm" do
        allow(ActiveRecall::LeitnerSystem).to receive(:right).and_return({})
        user.right_answer_for!(word)
        expect(ActiveRecall::LeitnerSystem).to have_received(:right)
      end
    end

    context "when overriding the default" do
      before do
        ActiveRecall.configure do |config|
          config.algorithm_class = ActiveRecall::FibonacciSequence
        end
      end

      it "uses the explicitly specified algorithm" do
        allow(ActiveRecall::FibonacciSequence).to receive(:right).and_return({})
        allow(ActiveRecall::LeitnerSystem).to receive(:right)
        user.right_answer_for!(word)
        expect(ActiveRecall::FibonacciSequence).to have_received(:right)
        expect(ActiveRecall::LeitnerSystem).not_to have_received(:right)
      end
    end
  end
end
