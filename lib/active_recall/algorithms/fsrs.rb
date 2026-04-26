# frozen_string_literal: true

require "active_recall/algorithms/fsrs/internal"

module ActiveRecall
  class FSRS
    REQUIRED_ATTRIBUTES = [
      :box,
      :stability,
      :difficulty,
      :state,
      :lapses,
      :elapsed_days,
      :scheduled_days,
      :times_right,
      :times_wrong,
      :last_reviewed,
      :grade
    ].freeze

    GRADE_TO_RATING = {
      1 => Internal::Rating::AGAIN,
      2 => Internal::Rating::HARD,
      3 => Internal::Rating::GOOD,
      4 => Internal::Rating::EASY
    }.freeze

    def self.required_attributes
      REQUIRED_ATTRIBUTES
    end

    def self.type
      :gradable
    end

    def self.score(**kwargs)
      new(**kwargs).score
    end

    def initialize(box:, stability:, difficulty:, state:, lapses:,
      elapsed_days:, scheduled_days:, times_right:, times_wrong:,
      last_reviewed:, grade:, current_time: Time.current)
      @box = box || 0
      @stability = stability
      @difficulty = difficulty
      @state = state || Internal::State::NEW
      @lapses = lapses || 0
      @elapsed_days = elapsed_days || 0
      @scheduled_days = scheduled_days || 0
      @times_right = times_right || 0
      @times_wrong = times_wrong || 0
      @last_reviewed = last_reviewed
      @grade = grade
      @current_time = current_time
    end

    def score
      raise "Grade must be between 1-4!" unless GRADE_TO_RATING.key?(@grade)

      now = to_utc_datetime(@current_time)
      scheduling = scheduler.repeat(build_card, now)
      result = scheduling[GRADE_TO_RATING[@grade]].card

      {
        box: result.reps,
        stability: result.stability,
        difficulty: result.difficulty,
        state: result.state,
        lapses: result.lapses,
        elapsed_days: result.elapsed_days,
        scheduled_days: result.scheduled_days,
        last_reviewed: result.last_review,
        next_review: result.due,
        times_right: @times_right + ((@grade >= 2) ? 1 : 0),
        times_wrong: @times_wrong + ((@grade == 1) ? 1 : 0)
      }
    end

    private

    def build_card
      card = Internal::Card.new
      card.stability = @stability if @stability
      card.difficulty = @difficulty if @difficulty
      card.state = @state
      card.lapses = @lapses
      card.elapsed_days = @elapsed_days
      card.scheduled_days = @scheduled_days
      card.reps = @box
      card.last_review = to_utc_datetime(@last_reviewed) if @last_reviewed
      card
    end

    def scheduler
      scheduler = Internal::Scheduler.new
      config = ActiveRecall.configuration
      scheduler.p.request_retention = config.fsrs_request_retention if config.fsrs_request_retention
      scheduler.p.maximum_interval = config.fsrs_maximum_interval if config.fsrs_maximum_interval
      scheduler.p.w = config.fsrs_weights if config.fsrs_weights
      scheduler
    end

    def to_utc_datetime(value)
      case value
      when DateTime then value.new_offset(0)
      else value.utc.to_datetime
      end
    end
  end
end
