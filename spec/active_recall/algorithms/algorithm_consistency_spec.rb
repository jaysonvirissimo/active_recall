# frozen_string_literal: true

require "spec_helper"

describe "Algorithm Consistency" do
  let(:current_time) { Time.current }

  describe "return value structure" do
    let(:binary_params) do
      {box: 2, times_right: 2, times_wrong: 1, current_time: current_time}
    end

    let(:gradable_params) do
      {box: 2, easiness_factor: 2.5, times_right: 2, times_wrong: 1, grade: 4, current_time: current_time}
    end

    describe "binary algorithms" do
      [ActiveRecall::LeitnerSystem, ActiveRecall::SoftLeitnerSystem, ActiveRecall::FibonacciSequence].each do |algorithm|
        context algorithm.name do
          describe "#right" do
            subject { algorithm.right(**binary_params) }

            it "returns required keys" do
              expect(subject.keys).to include(:box, :times_right, :times_wrong, :last_reviewed, :next_review)
            end

            it "returns Integer for box" do
              expect(subject[:box]).to be_kind_of(Integer)
            end

            it "returns Integer for times_right" do
              expect(subject[:times_right]).to be_kind_of(Integer)
            end

            it "returns Integer for times_wrong" do
              expect(subject[:times_wrong]).to be_kind_of(Integer)
            end

            it "returns Time for last_reviewed" do
              expect(subject[:last_reviewed]).to be_kind_of(Time)
            end

            it "sets last_reviewed to current_time" do
              expect(subject[:last_reviewed]).to eq(current_time)
            end

            it "returns Time or nil for next_review" do
              expect(subject[:next_review]).to be_kind_of(Time).or(be_nil)
            end
          end

          describe "#wrong" do
            subject { algorithm.wrong(**binary_params) }

            it "returns required keys" do
              expect(subject.keys).to include(:box, :times_right, :times_wrong, :last_reviewed, :next_review)
            end

            it "returns Integer for box" do
              expect(subject[:box]).to be_kind_of(Integer)
            end

            it "returns Integer for times_right" do
              expect(subject[:times_right]).to be_kind_of(Integer)
            end

            it "returns Integer for times_wrong" do
              expect(subject[:times_wrong]).to be_kind_of(Integer)
            end

            it "returns Time for last_reviewed" do
              expect(subject[:last_reviewed]).to be_kind_of(Time)
            end

            it "sets last_reviewed to current_time" do
              expect(subject[:last_reviewed]).to eq(current_time)
            end
          end
        end
      end
    end

    describe "gradable algorithms" do
      [ActiveRecall::SM2].each do |algorithm|
        context algorithm.name do
          describe "#score" do
            subject { algorithm.score(**gradable_params) }

            it "returns required keys" do
              expect(subject.keys).to include(:box, :times_right, :times_wrong, :last_reviewed, :next_review, :easiness_factor)
            end

            it "returns Integer for box" do
              expect(subject[:box]).to be_kind_of(Integer)
            end

            it "returns Integer for times_right" do
              expect(subject[:times_right]).to be_kind_of(Integer)
            end

            it "returns Integer for times_wrong" do
              expect(subject[:times_wrong]).to be_kind_of(Integer)
            end

            it "returns Time for last_reviewed" do
              expect(subject[:last_reviewed]).to be_kind_of(Time)
            end

            it "sets last_reviewed to current_time" do
              expect(subject[:last_reviewed]).to eq(current_time)
            end

            it "returns Time for next_review" do
              expect(subject[:next_review]).to be_kind_of(Time)
            end

            it "returns Numeric for easiness_factor" do
              expect(subject[:easiness_factor]).to be_kind_of(Numeric)
            end
          end
        end
      end
    end
  end

  describe "algorithm types" do
    describe "binary algorithms" do
      [ActiveRecall::LeitnerSystem, ActiveRecall::SoftLeitnerSystem, ActiveRecall::FibonacciSequence].each do |algorithm|
        context algorithm.name do
          it "returns :binary for type" do
            expect(algorithm.type).to eq(:binary)
          end

          it "responds to right" do
            expect(algorithm).to respond_to(:right)
          end

          it "responds to wrong" do
            expect(algorithm).to respond_to(:wrong)
          end

          it "does not respond to score" do
            expect(algorithm).not_to respond_to(:score)
          end
        end
      end
    end

    describe "gradable algorithms" do
      [ActiveRecall::SM2].each do |algorithm|
        context algorithm.name do
          it "returns :gradable for type" do
            expect(algorithm.type).to eq(:gradable)
          end

          it "responds to score" do
            expect(algorithm).to respond_to(:score)
          end

          it "does not respond to right" do
            expect(algorithm).not_to respond_to(:right)
          end

          it "does not respond to wrong" do
            expect(algorithm).not_to respond_to(:wrong)
          end
        end
      end
    end
  end

  describe "required_attributes" do
    [ActiveRecall::LeitnerSystem, ActiveRecall::SoftLeitnerSystem, ActiveRecall::FibonacciSequence, ActiveRecall::SM2].each do |algorithm|
      context algorithm.name do
        it "returns an array of symbols" do
          expect(algorithm.required_attributes).to be_kind_of(Array)
          expect(algorithm.required_attributes).to all(be_kind_of(Symbol))
        end

        it "includes :box" do
          expect(algorithm.required_attributes).to include(:box)
        end

        it "includes :times_right" do
          expect(algorithm.required_attributes).to include(:times_right)
        end

        it "includes :times_wrong" do
          expect(algorithm.required_attributes).to include(:times_wrong)
        end
      end
    end

    context "SM2 (gradable)" do
      it "additionally requires :easiness_factor and :grade" do
        expect(ActiveRecall::SM2.required_attributes).to include(:easiness_factor, :grade)
      end
    end
  end

  describe "counter tracking consistency" do
    let(:initial_state) do
      {box: 3, times_right: 5, times_wrong: 2, current_time: current_time}
    end

    [ActiveRecall::LeitnerSystem, ActiveRecall::SoftLeitnerSystem, ActiveRecall::FibonacciSequence].each do |algorithm|
      context algorithm.name do
        describe "on right answer" do
          subject { algorithm.right(**initial_state) }

          it "increments times_right by exactly 1" do
            expect(subject[:times_right]).to eq(initial_state[:times_right] + 1)
          end

          it "does not change times_wrong" do
            expect(subject[:times_wrong]).to eq(initial_state[:times_wrong])
          end
        end

        describe "on wrong answer" do
          subject { algorithm.wrong(**initial_state) }

          it "does not change times_right" do
            expect(subject[:times_right]).to eq(initial_state[:times_right])
          end

          it "increments times_wrong by exactly 1" do
            expect(subject[:times_wrong]).to eq(initial_state[:times_wrong] + 1)
          end
        end
      end
    end

    context "SM2" do
      let(:sm2_initial_state) do
        initial_state.merge(easiness_factor: 2.5, grade: 5)
      end

      describe "on successful response (grade >= 3)" do
        subject { ActiveRecall::SM2.score(**sm2_initial_state.merge(grade: 5)) }

        it "increments times_right by exactly 1" do
          expect(subject[:times_right]).to eq(sm2_initial_state[:times_right] + 1)
        end

        it "does not change times_wrong" do
          expect(subject[:times_wrong]).to eq(sm2_initial_state[:times_wrong])
        end
      end

      describe "on failed response (grade < 3)" do
        subject { ActiveRecall::SM2.score(**sm2_initial_state.merge(grade: 2)) }

        it "does not change times_right" do
          expect(subject[:times_right]).to eq(sm2_initial_state[:times_right])
        end

        it "increments times_wrong by exactly 1" do
          expect(subject[:times_wrong]).to eq(sm2_initial_state[:times_wrong] + 1)
        end
      end
    end
  end

  describe "box behavior on wrong answers" do
    let(:params) { {box: 5, times_right: 5, times_wrong: 0, current_time: current_time} }

    context "hard reset algorithms (LeitnerSystem, FibonacciSequence)" do
      [ActiveRecall::LeitnerSystem, ActiveRecall::FibonacciSequence].each do |algorithm|
        context algorithm.name do
          it "resets box to 0" do
            result = algorithm.wrong(**params)
            expect(result[:box]).to eq(0)
          end
        end
      end
    end

    context "soft reset algorithm (SoftLeitnerSystem)" do
      it "decrements box by 1" do
        result = ActiveRecall::SoftLeitnerSystem.wrong(**params)
        expect(result[:box]).to eq(4)
      end
    end

    context "SM2" do
      let(:sm2_params) { params.merge(easiness_factor: 2.5, grade: 2) }

      it "resets box to 0" do
        result = ActiveRecall::SM2.score(**sm2_params)
        expect(result[:box]).to eq(0)
      end
    end
  end

  describe "box behavior on right answers" do
    let(:params) { {box: 3, times_right: 3, times_wrong: 0, current_time: current_time} }

    context "algorithms that increment box without cap" do
      [ActiveRecall::LeitnerSystem, ActiveRecall::FibonacciSequence].each do |algorithm|
        context algorithm.name do
          it "increments box by 1" do
            result = algorithm.right(**params)
            expect(result[:box]).to eq(4)
          end

          it "allows box to grow beyond DELAYS.count" do
            high_box_params = params.merge(box: 10)
            result = algorithm.right(**high_box_params)
            expect(result[:box]).to eq(11)
          end
        end
      end
    end

    context "SoftLeitnerSystem (caps box)" do
      it "increments box by 1 within limit" do
        result = ActiveRecall::SoftLeitnerSystem.right(**params)
        expect(result[:box]).to eq(4)
      end

      it "caps box at DELAYS.count (7)" do
        high_box_params = params.merge(box: 7)
        result = ActiveRecall::SoftLeitnerSystem.right(**high_box_params)
        expect(result[:box]).to eq(7)
      end
    end

    context "SM2" do
      let(:sm2_params) { params.merge(easiness_factor: 2.5, grade: 5) }

      it "increments box by 1" do
        result = ActiveRecall::SM2.score(**sm2_params)
        expect(result[:box]).to eq(4)
      end

      it "allows box to grow without cap" do
        high_box_params = sm2_params.merge(box: 10)
        result = ActiveRecall::SM2.score(**high_box_params)
        expect(result[:box]).to eq(11)
      end
    end
  end
end
