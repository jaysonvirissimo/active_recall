# frozen_string_literal: true

require "spec_helper"

describe "active_recall.gemspec" do
  let(:specification) do
    Gem::Specification.load(File.expand_path("../../active_recall.gemspec", __dir__))
  end

  it "depends on upstream fsrs with the first Rails 8-compatible fixed release" do
    dependency = specification.runtime_dependencies.find { |dep| dep.name == "fsrs" }

    expect(dependency).not_to be_nil
    expect(dependency.requirement).to eq(Gem::Requirement.new(">= 0.9.2", "< 1.0"))
  end

  it "does not keep vendored FSRS license documentation" do
    vendored_licenses_path = File.expand_path(
      File.join("..", "..", %w[VEN DORED_LICENSES.md].join),
      __dir__
    )

    expect(File.exist?(vendored_licenses_path)).to be(false)
  end
end
