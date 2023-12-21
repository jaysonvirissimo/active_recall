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
