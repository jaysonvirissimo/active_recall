# frozen_string_literal: true

module ActiveRecall
  class SM2
    MIN_EASINESS_FACTOR = 1.3

    def self.score(box:, easiness_factor:, times_right:, times_wrong:, grade:, current_time: Time.current)
      new(
        box: box,
        easiness_factor: easiness_factor,
        times_right: times_right,
        times_wrong: times_wrong,
        grade: grade,
        current_time: current_time
      ).score
    end

    def initialize(box:, easiness_factor:, times_right:, times_wrong:, grade:, current_time: Time.current)
      @box = box
      @easiness_factor = easiness_factor || 2.5
      @times_right = times_right
      @times_wrong = times_wrong
      @grade = grade
      @current_time = current_time
      @interval = [1, box].max
    end

    def score
      raise "Grade must be between 0-5!" unless GRADES.include?(@grade)
      update_easiness_factor
      update_repetition_and_interval

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
      5, # Perfect response. The learner recalls the information without hesitation.
      4, # Correct response after a hesitation. The learner recalls the information but with some difficulty.
      3, # Correct response recalled with serious difficulty. The learner struggles but eventually recalls the information.
      2, # Incorrect response, but the learner was very close to the correct answer. This might involve recalling some of the information correctly but not all of it.
      1, # Incorrect response, but the learner feels they should have remembered it. This is typically used when the learner has a sense of familiarity with the material but fails to recall it correctly.
      0 # Complete blackout. The learner does not recall the information at all.
    ].freeze

    def update_easiness_factor
      @easiness_factor += (0.1 - (5 - @grade) * (0.08 + (5 - @grade) * 0.02))
      @easiness_factor = [@easiness_factor, MIN_EASINESS_FACTOR].max
    end

    def update_repetition_and_interval
      if @grade >= 3
        @box += 1
        @times_right += 1
        @interval = case @box
        when 1
          1
        when 2
          6
        else
          (@interval || 1) * @easiness_factor
        end
      else
        @box = 0
        @times_wrong += 1
        @interval = 1
      end
    end

    def next_review
      @current_time + @interval.days
    end
  end
end
