# frozen_string_literal: true

require "spec_helper"

describe ActiveRecall::LeitnerSystem do
  it_behaves_like "binary spaced repetition algorithms"

  describe ".required_attributes" do
    specify do
      expect(described_class.required_attributes).to contain_exactly(
        :box,
        :times_right,
        :times_wrong
      )
    end
  end
end
