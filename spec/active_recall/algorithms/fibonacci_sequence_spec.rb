# frozen_string_literal: true

require 'spec_helper'

describe ActiveRecall::FibonacciSequence do
  it_behaves_like 'spaced repetition algorithms'

  describe '.right' do
    subject { described_class.right(**arguments) }

    context 'on the first attempt' do
      let(:arguments) do
        { box: 0, current_time: current_time, times_right: 0, times_wrong: 0 }
      end
      let(:current_time) { Time.parse('2019-10-13 15:00:00 -0700') }
      let(:expected_next_review) { Time.parse('2019-10-14 15:00:00 -0700') }

      it 'schedules the next review for the next day' do
        expect(subject.fetch(:next_review)).to eq(expected_next_review)
      end
    end

    context 'on the second attempt' do
      let(:arguments) do
        { box: 1, current_time: current_time, times_right: 1, times_wrong: 0 }
      end
      let(:current_time) { Time.parse('2019-10-15 15:00:00 -0700') }
      let(:expected_next_review) { Time.parse('2019-10-16 15:00:00 -0700') }

      it 'schedules the next review for the next day' do
        expect(subject.fetch(:next_review)).to eq(expected_next_review)
      end
    end

    context 'on the third attempt' do
      let(:arguments) do
        { box: 2, current_time: current_time, times_right: 2, times_wrong: 0 }
      end
      let(:current_time) { Time.parse('2019-10-16 15:00:00 -0700') }
      let(:expected_next_review) { Time.parse('2019-10-18 15:00:00 -0700') }

      it 'schedules the next review for two days later' do
        expect(subject.fetch(:next_review)).to eq(expected_next_review)
      end
    end

    context 'on the fourth attempt' do
      let(:arguments) do
        { box: 3, current_time: current_time, times_right: 3, times_wrong: 0 }
      end
      let(:current_time) { Time.parse('2019-10-19 15:00:00 -0700') }
      let(:expected_next_review) { Time.parse('2019-10-22 15:00:00 -0700') }

      it 'schedules the next review for three days later' do
        expect(subject.fetch(:next_review)).to eq(expected_next_review)
      end
    end
  end

  describe '.wrong' do
    let(:current_time) { Time.current }
    subject { described_class.wrong(**arguments) }

    context 'on the first attempt' do
      let(:arguments) do
        { box: 0, current_time: current_time, times_right: 0, times_wrong: 0 }
      end

      it 'results in no next review' do
        expect(subject.fetch(:next_review)).not_to be
      end

      it 'returns the same box given' do
        expect(subject.fetch(:box)).to be_zero
      end

      it 'does not change the times right' do
        expect(subject.fetch(:times_right)).to eq(arguments[:times_right])
      end

      it 'increments the times wrong' do
        expect(subject.fetch(:times_wrong)).to eq(1)
      end
    end

    context 'on the second attempt' do
      let(:arguments) do
        { box: 1, current_time: current_time, times_right: 1, times_wrong: 0 }
      end

      it 'places back into the minimal box' do
        expect(subject.fetch(:box)).to be_zero
      end

      it 'increments the times wrong' do
        expect(subject.fetch(:times_wrong)).to eq(1)
      end

      it 'will leave the times right as is' do
        expect(subject.fetch(:times_right)).to eq(1)
      end
    end
  end

  describe '#fibonacci_number_at' do
    let(:instance) do
      described_class.new(box: 0, times_right: 0, times_wrong: 0)
    end

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
  end
end
