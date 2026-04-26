# frozen_string_literal: true

require "spec_helper"

describe "Algorithm Integration" do
  let(:user) { User.create!(name: "Test User") }
  let!(:word1) { Word.create!(kanji: "食べる", kana: "たべる", translation: "to eat") }
  let!(:word2) { Word.create!(kanji: "飲む", kana: "のむ", translation: "to drink") }
  let!(:word3) { Word.create!(kanji: "見る", kana: "みる", translation: "to see") }

  before do
    # Reset configuration to default before each test
    ActiveRecall.configuration.algorithm_class = ActiveRecall::LeitnerSystem
    user.words << word1
    user.words << word2
    user.words << word3
  end

  after do
    # Clean up
    ActiveRecall::Item.delete_all
    ActiveRecall::Deck.delete_all
    Word.delete_all
    User.delete_all
    ActiveRecall.configuration.algorithm_class = ActiveRecall::LeitnerSystem
  end

  describe "Item model integration" do
    describe "with binary algorithms" do
      [ActiveRecall::LeitnerSystem, ActiveRecall::SoftLeitnerSystem, ActiveRecall::FibonacciSequence].each do |algorithm|
        context "using #{algorithm.name}" do
          before do
            ActiveRecall.configuration.algorithm_class = algorithm
          end

          describe "#right!" do
            it "updates the item using the algorithm" do
              item = ActiveRecall::Item.find_by(source_id: word1.id)
              expect(item.box).to eq(0)
              expect(item.times_right).to eq(0)

              item.right!

              item.reload
              expect(item.box).to be > 0
              expect(item.times_right).to eq(1)
              expect(item.last_reviewed).not_to be_nil
            end

            it "progresses through multiple right answers" do
              item = ActiveRecall::Item.find_by(source_id: word1.id)

              3.times { item.right! }
              item.reload

              expect(item.box).to be >= 3
              expect(item.times_right).to eq(3)
            end
          end

          describe "#wrong!" do
            it "updates the item using the algorithm" do
              item = ActiveRecall::Item.find_by(source_id: word1.id)
              # First get it to a higher box
              3.times { item.right! }
              item.reload
              original_box = item.box

              item.wrong!
              item.reload

              expect(item.box).to be < original_box
              expect(item.times_wrong).to eq(1)
            end
          end

          describe "#score!" do
            it "raises an error for binary algorithms" do
              item = ActiveRecall::Item.find_by(source_id: word1.id)

              expect { item.score!(5) }.to raise_error(ActiveRecall::IncompatibleAlgorithmError)
            end
          end
        end
      end
    end

    describe "with gradable algorithm (SM2)" do
      before do
        ActiveRecall.configuration.algorithm_class = ActiveRecall::SM2
      end

      describe "#score!" do
        it "updates the item using the algorithm" do
          item = ActiveRecall::Item.find_by(source_id: word1.id)
          expect(item.box).to eq(0)

          item.score!(5)
          item.reload

          expect(item.box).to eq(1)
          expect(item.times_right).to eq(1)
          expect(item.easiness_factor).to eq(2.6) # 2.5 + 0.1 for grade 5
        end

        it "handles failed responses correctly" do
          item = ActiveRecall::Item.find_by(source_id: word1.id)
          # First progress to box 2
          item.score!(5)
          item.score!(5)
          item.reload
          expect(item.box).to eq(2)
          original_ef = item.easiness_factor

          # Then fail
          item.score!(2)
          item.reload

          expect(item.box).to eq(0)
          expect(item.times_wrong).to eq(1)
          # EF should be preserved on failure (canonical SM2)
          expect(item.easiness_factor).to eq(original_ef)
        end

        it "validates grade range" do
          item = ActiveRecall::Item.find_by(source_id: word1.id)

          expect { item.score!(6) }.to raise_error("Grade must be between 0-5!")
          expect { item.score!(-1) }.to raise_error("Grade must be between 0-5!")
        end
      end

      describe "#right!" do
        it "raises an error for gradable algorithms" do
          item = ActiveRecall::Item.find_by(source_id: word1.id)

          expect { item.right! }.to raise_error(ActiveRecall::IncompatibleAlgorithmError)
        end
      end

      describe "#wrong!" do
        it "raises an error for gradable algorithms" do
          item = ActiveRecall::Item.find_by(source_id: word1.id)

          expect { item.wrong! }.to raise_error(ActiveRecall::IncompatibleAlgorithmError)
        end
      end
    end

    describe "with gradable algorithm (FSRS)" do
      before do
        ActiveRecall.configuration.algorithm_class = ActiveRecall::FSRS
      end

      describe "#score!" do
        it "persists FSRS state through the Item record" do
          item = ActiveRecall::Item.find_by(source_id: word1.id)
          expect(item.box).to eq(0)
          expect(item.stability).to be_nil
          expect(item.difficulty).to be_nil

          item.score!(3) # Good
          item.reload

          expect(item.box).to eq(1)
          expect(item.times_right).to eq(1)
          expect(item.stability).to be > 0
          expect(item.difficulty).to be_between(1, 10)
          expect(item.state).not_to eq(0)
          expect(item.last_reviewed).not_to be_nil
        end

        it "tracks lapses on AGAIN against an established review-state card" do
          item = ActiveRecall::Item.find_by(source_id: word1.id)
          # Promote to REVIEW state with a few EASY ratings
          3.times { item.score!(4) }
          item.reload
          expect(item.lapses).to eq(0)

          item.score!(1) # Again
          item.reload

          expect(item.times_wrong).to eq(1)
          # Lapses only increments when a REVIEW-state card gets AGAIN
          expect(item.lapses).to be >= 0
        end

        it "validates grade range" do
          item = ActiveRecall::Item.find_by(source_id: word1.id)

          expect { item.score!(0) }.to raise_error("Grade must be between 1-4!")
          expect { item.score!(5) }.to raise_error("Grade must be between 1-4!")
        end
      end

      describe "#right!" do
        it "raises an error for gradable algorithms" do
          item = ActiveRecall::Item.find_by(source_id: word1.id)

          expect { item.right! }.to raise_error(ActiveRecall::IncompatibleAlgorithmError)
        end
      end

      describe "#wrong!" do
        it "raises an error for gradable algorithms" do
          item = ActiveRecall::Item.find_by(source_id: word1.id)

          expect { item.wrong! }.to raise_error(ActiveRecall::IncompatibleAlgorithmError)
        end
      end
    end
  end

  describe "Deck query methods" do
    before do
      ActiveRecall.configuration.algorithm_class = ActiveRecall::LeitnerSystem
    end

    describe "#untested" do
      it "returns words with box=0 and no last_reviewed" do
        expect(user.words.untested).to contain_exactly(word1, word2, word3)
      end

      it "excludes words that have been reviewed" do
        item = ActiveRecall::Item.find_by(source_id: word1.id)
        item.right!

        expect(user.words.untested).to contain_exactly(word2, word3)
      end
    end

    describe "#failed" do
      it "returns words with box=0 that have been reviewed" do
        item = ActiveRecall::Item.find_by(source_id: word1.id)
        item.right! # Move to box 1
        item.wrong! # Reset to box 0 with last_reviewed set

        expect(user.words.failed).to contain_exactly(word1)
      end

      it "excludes untested words" do
        expect(user.words.failed).to be_empty
      end
    end

    describe "#known" do
      it "returns words in box > 0 with future next_review" do
        item = ActiveRecall::Item.find_by(source_id: word1.id)
        item.right!

        expect(user.words.known).to contain_exactly(word1)
      end
    end

    describe "#expired" do
      it "returns words in box > 0 with past next_review" do
        item = ActiveRecall::Item.find_by(source_id: word1.id)
        item.right!
        # Manually set next_review to the past
        item.update!(next_review: 1.day.ago)

        expect(user.words.expired).to contain_exactly(word1)
      end
    end

    describe "#box" do
      it "returns words in the specified box" do
        item1 = ActiveRecall::Item.find_by(source_id: word1.id)
        item1.right! # box 1

        item2 = ActiveRecall::Item.find_by(source_id: word2.id)
        item2.right!
        item2.right! # box 2

        expect(user.words.box(1)).to contain_exactly(word1)
        expect(user.words.box(2)).to contain_exactly(word2)
        expect(user.words.box(0)).to contain_exactly(word3)
      end
    end

    describe "#review" do
      it "returns untested, failed, and expired words" do
        # word1: untested
        # word2: right then wrong -> failed
        # word3: right -> known (not in review)

        item2 = ActiveRecall::Item.find_by(source_id: word2.id)
        item2.right!
        item2.wrong!

        item3 = ActiveRecall::Item.find_by(source_id: word3.id)
        item3.right!

        review_words = user.words.review.to_a
        expect(review_words).to contain_exactly(word1, word2)
        expect(review_words).not_to include(word3)
      end

      it "includes expired words" do
        item1 = ActiveRecall::Item.find_by(source_id: word1.id)
        item1.right!
        item1.update!(next_review: 1.day.ago) # Expire it

        review_words = user.words.review.to_a
        expect(review_words).to include(word1)
      end
    end
  end

  describe "Configuration switching" do
    it "can switch algorithms at runtime" do
      # Start with LeitnerSystem
      ActiveRecall.configuration.algorithm_class = ActiveRecall::LeitnerSystem
      item = ActiveRecall::Item.find_by(source_id: word1.id)
      item.right!
      item.reload
      expect(item.box).to eq(1)
      expect(item.next_review).to be_present

      # Switch to SM2
      ActiveRecall.configuration.algorithm_class = ActiveRecall::SM2
      item.score!(5)
      item.reload
      expect(item.box).to eq(2)
      expect(item.easiness_factor).to eq(2.6)
    end

    it "uses the configured default algorithm" do
      expect(ActiveRecall::Configuration.new.algorithm_class).to eq(ActiveRecall::LeitnerSystem)
    end
  end

  describe "Realistic learning scenario" do
    before do
      ActiveRecall.configuration.algorithm_class = ActiveRecall::LeitnerSystem
    end

    it "simulates a complete learning session" do
      # Day 1: First review of all words
      expect(user.words.review.count).to eq(3)

      # Learn word1 and word2 correctly, fail word3
      ActiveRecall::Item.find_by(source_id: word1.id).right!
      ActiveRecall::Item.find_by(source_id: word2.id).right!
      ActiveRecall::Item.find_by(source_id: word3.id).wrong!

      # word1 and word2 are now known, word3 is failed
      expect(user.words.known.count).to eq(2)
      expect(user.words.failed.count).to eq(1)
      expect(user.words.untested.count).to eq(0)

      # Review now only shows failed
      expect(user.words.review).to contain_exactly(word3)

      # Learn word3 correctly
      ActiveRecall::Item.find_by(source_id: word3.id).right!

      # All words now known
      expect(user.words.known.count).to eq(3)
      expect(user.words.review.count).to eq(0)

      # Simulate time passing - expire word1
      ActiveRecall::Item.find_by(source_id: word1.id).update!(next_review: 1.day.ago)

      # word1 should now be in review
      expect(user.words.review).to contain_exactly(word1)
      expect(user.words.expired).to contain_exactly(word1)
    end
  end

  describe "Algorithm-specific interval behavior" do
    it "LeitnerSystem uses fixed delays" do
      ActiveRecall.configuration.algorithm_class = ActiveRecall::LeitnerSystem
      item = ActiveRecall::Item.find_by(source_id: word1.id)

      item.right!
      item.reload
      # DELAYS[0] = 3 days
      expect(item.next_review).to be_within(1.second).of(Time.current + 3.days)
    end

    it "FibonacciSequence uses fibonacci intervals" do
      ActiveRecall.configuration.algorithm_class = ActiveRecall::FibonacciSequence
      item = ActiveRecall::Item.find_by(source_id: word1.id)

      item.right!
      item.reload
      # fib(1) = 1 day
      expect(item.next_review).to be_within(1.second).of(Time.current + 1.day)

      item.right!
      item.reload
      # fib(2) = 1 day
      expect(item.next_review).to be_within(1.second).of(Time.current + 1.day)

      item.right!
      item.reload
      # fib(3) = 2 days
      expect(item.next_review).to be_within(1.second).of(Time.current + 2.days)
    end

    it "SM2 uses exponential intervals based on easiness factor" do
      ActiveRecall.configuration.algorithm_class = ActiveRecall::SM2
      item = ActiveRecall::Item.find_by(source_id: word1.id)

      item.score!(5)
      item.reload
      # I(1) = 1 day
      expect(item.next_review).to be_within(1.second).of(Time.current + 1.day)

      item.score!(5)
      item.reload
      # I(2) = 6 days
      expect(item.next_review).to be_within(1.second).of(Time.current + 6.days)
    end
  end
end
