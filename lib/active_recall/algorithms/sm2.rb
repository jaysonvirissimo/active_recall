module ActiveRecall
  class SM2
    MIN_EASINESS_FACTOR = 1.3

    def self.required_attributes
      REQUIRED_ATTRIBUTES
    end

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

    def self.type
      :gradable
    end

    def initialize(box:, easiness_factor:, times_right:, times_wrong:, grade:, current_time: Time.current)
      @box = box # box serves as repetition number n
      @easiness_factor = easiness_factor || 2.5
      @times_right = times_right
      @times_wrong = times_wrong
      @grade = grade
      @current_time = current_time
      @interval = case box
      when 0 then 1  # First review
      when 1 then 6  # Second review
      else 17       # Will be overwritten for boxes > 1
      end
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
      :times_wrong
    ].freeze

    def update_easiness_factor
      @easiness_factor += (0.1 - (5 - @grade) * (0.08 + (5 - @grade) * 0.02))
      @easiness_factor = [@easiness_factor, MIN_EASINESS_FACTOR].max
    end

    def update_repetition_and_interval(old_ef)
      if @grade >= 3
        @interval = if @box == 0
          1
        elsif @box == 1
          6
        else
          last_interval = (@box == 2) ? 6 : @interval
          # First convert to float then round to avoid floating point issues
          (last_interval.to_f * old_ef).round
        end

        @box += 1
        @times_right += 1
      else
        @box = 0
        @interval = 1
        @times_wrong += 1
      end
    end

    def next_review
      @current_time + @interval.days
    end
  end
end
