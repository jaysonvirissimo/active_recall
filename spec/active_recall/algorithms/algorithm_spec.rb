# frozen_string_literal: true

shared_examples_for "binary spaced repetition algorithms" do
  it { expect(described_class).to respond_to(:right) }
  it { expect(described_class).to respond_to(:wrong) }

  context ".type" do
    it { expect(described_class.type).to eq(:binary) }
  end

  context "when given API-respecting arguments" do
    let(:arguments) { {box: 0, times_right: 0, times_wrong: 0} }
    let(:expected_keys) do
      %i[box times_right times_wrong last_reviewed next_review]
    end

    describe "#right" do
      let(:result) { described_class.new(**arguments).right }

      it "returns attributes needed to update the ActiveRecord model" do
        expect(result.keys).to include(*expected_keys)
        expect(result[:box]).to be_kind_of(Integer)
        expect(result[:times_right]).to be_kind_of(Integer)
        expect(result[:times_wrong]).to be_kind_of(Integer)
        expect(result[:last_reviewed]).to be_kind_of(Time)
        expect(result[:next_review]).to be_kind_of(Time)
      end
    end

    describe "#wrong" do
      let(:result) { described_class.new(**arguments).wrong }

      it "returns attributes needed to update the ActiveRecord model" do
        expect(result.keys).to include(*expected_keys)
        expect(result[:box]).to be_kind_of(Integer)
        expect(result[:times_right]).to be_kind_of(Integer)
        expect(result[:times_wrong]).to be_kind_of(Integer)
        expect(result[:last_reviewed]).to be_kind_of(Time)
      end
    end
  end
end
