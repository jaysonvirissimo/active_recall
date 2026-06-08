# frozen_string_literal: true

module ActiveRecall
  class SM2
    MIN_EASINESS_FACTOR = 1.3

    def self.required_attributes
      REQUIRED_ATTRIBUTES
    end

    def self.score(box:, easiness_factor:, times_right:, times_wrong:, grade:, last_reviewed: nil, next_review: nil, current_time: Time.current)
      new(
        box: box,
        easiness_factor: easiness_factor,
        times_right: times_right,
        times_wrong: times_wrong,
        grade: grade,
        last_reviewed: last_reviewed,
        next_review: next_review,
        current_time: current_time
      ).score
    end

    def self.type
      :gradable
    end

    def initialize(box:, easiness_factor:, times_right:, times_wrong:, grade:, last_reviewed: nil, next_review: nil, current_time: Time.current)
      @box = box # box serves as repetition number n
      @easiness_factor = easiness_factor || 2.5
      @times_right = times_right
      @times_wrong = times_wrong
      @grade = grade
      @last_reviewed = last_reviewed       # the card's prior review time
      @previous_next_review = next_review   # the card's prior scheduled due date
      @current_time = current_time
      @interval = 1
    end

    def score
      raise "Grade must be between 0-5!" unless GRADES.include?(@grade)
      old_ef = @easiness_factor
      update_easiness_factor
      update_repetition_and_interval(old_ef)

      {
        box: @box,
        easiness_factor: @easiness_factor,
        times_right: @times_right,
        times_wrong: @times_wrong,
        last_reviewed: @current_time,
        next_review: next_review
      }
    end

    private

    GRADES = [
      5, # Perfect response
      4, # Correct response after a hesitation
      3, # Correct response recalled with serious difficulty
      2, # Incorrect response, but close
      1, # Incorrect response with familiarity
      0  # Complete blackout
    ].freeze

    REQUIRED_ATTRIBUTES = [
      :box,
      :easiness_factor,
      :grade,
      :times_right,
      :times_wrong,
      :last_reviewed,
      :next_review
    ].freeze

    def update_easiness_factor
      @easiness_factor += (0.1 - (5 - @grade) * (0.08 + (5 - @grade) * 0.02))
      @easiness_factor = [@easiness_factor, MIN_EASINESS_FACTOR].max
    end

    def update_repetition_and_interval(old_ef)
      if @grade >= 3
        # Canonical SM-2 recurrence: I(1)=1, I(2)=6, I(n)=round(I(n-1) * EF).
        # EF here is the value from before this review's update (old_ef), which
        # reproduces the published Delphi sequence (1, 6, 16, 45, 131, 393).
        @interval = case @box
        when 0 then 1
        when 1 then 6
        else (previous_interval * old_ef).round
        end

        @box += 1
        @times_right += 1
      else
        @box = 0
        @interval = 1
        @times_wrong += 1
      end
    end

    # Recover the card's previously scheduled interval (in days) from its stored
    # timestamps. Falls back to I(2)=6 when the prior schedule is unavailable
    # (e.g. a card whose history predates this calculation).
    def previous_interval
      return 6 unless @last_reviewed && @previous_next_review

      [((@previous_next_review - @last_reviewed) / 1.day).round, 1].max
    end

    def next_review
      @current_time + @interval.days
    end
  end
end
