# ActiveRecall

**ActiveRecall** is a spaced-repetition system that allows you to treat arbitrary [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord) models as if they were flashcards to be learned and reviewed.
It is based on, and is intended to be backwards compatible with, the [okubo](https://github.com/rgravina/okubo) gem.
The primary differentiating features are that it lets the user specify the scheduling algorithm and is fully compatible with (and requires) Rails 6+ and Ruby 3+.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_recall'
```

And then execute:

    $ bundle
    $ rails generate active_recall
    $ rails db:migrate

Or, if you were using the Okubo gem and want to migrate your data over, execute:

    $ bundle
    $ rails generate active_recall --migrate_data true
    $ rails db:migrate

Or install it yourself as:

    $ gem install active_recall

The generator creates all the migrations any algorithm needs (including the `easiness_factor` column for SM2 and the FSRS-specific columns), so you don't have to revisit migrations when you switch algorithms later.

## Quick Start

The fastest way to get going — no algorithm choice, no grade scale, just right/wrong feedback. This uses the default `LeitnerSystem`.

Suppose you have an application allowing your users to study words in a foreign language. Use `has_deck` to set up a deck of flashcards:

```ruby
class Word < ActiveRecord::Base
end

class User < ActiveRecord::Base
  has_deck :words
end

user = User.create!(name: "Robert")
word = Word.create!(kanji: "日本語", kana: "にほんご", translation: "Japanese language")

user.words << word
user.words.untested  #=> [word]

user.right_answer_for!(word)
user.words.known     #=> [word]

user.wrong_answer_for!(word)
user.words.failed    #=> [word]
```

That's it. Want graded feedback (Again/Hard/Good/Easy) or modern scheduling? See [Choosing an Algorithm](#choosing-an-algorithm) below.

## Choosing an Algorithm

> **Not sure which to pick?** Stick with the default `LeitnerSystem` — it works out of the box and only needs right/wrong feedback. Reach for `FSRS` when you want modern, evidence-based scheduling and are willing to collect 1–4 ratings ("Again / Hard / Good / Easy") from users.

The full menu, in increasing order of sophistication:

| Algorithm | Type | How you grade | Reach for it when |
|---|---|---|---|
| **`LeitnerSystem`** *(default — start here)* | binary | `right_answer_for!` / `wrong_answer_for!` | You want the simplest thing that works |
| `SoftLeitnerSystem` | binary | `right_answer_for!` / `wrong_answer_for!` | Leitner is too punishing on occasional lapses |
| `FibonacciSequence` | binary | `right_answer_for!` / `wrong_answer_for!` | You want faster-growing intervals than Leitner |
| `SM2` | gradable | `score!(0..5, item)` | You want the classic SuperMemo behavior users know from Anki |
| **`FSRS`** *(modern recommendation)* | gradable | `score!(1..4, item)` | You're building something serious and want best-in-class retention |

**Binary** algorithms expect right-or-wrong feedback (`user.right_answer_for!(item)` / `user.wrong_answer_for!(item)`). **Gradable** algorithms expect a numeric grade per review (`user.score!(grade, item)`). Mixing them — e.g. calling `right_answer_for!` while configured to use SM2 — raises `ActiveRecall::IncompatibleAlgorithmError`.

## Configuration

Skip this section if you're sticking with the default `LeitnerSystem` — there's nothing to configure.

To switch algorithms, set `algorithm_class` from a Rails [initializer file](https://guides.rubyonrails.org/configuring.html#using-initializer-files):

```ruby
# config/initializers/active_recall.rb
ActiveRecall.configure do |config|
  config.algorithm_class = ActiveRecall::FSRS  # or SM2, SoftLeitnerSystem, FibonacciSequence
end
```

### FSRS-specific configuration

FSRS exposes three optional knobs. All have sensible defaults; tune only if you have a reason to:

- `fsrs_request_retention` — target retention probability (default `0.9`). Lower → longer intervals, more forgetting tolerated.
- `fsrs_maximum_interval` — caps the scheduled interval, in days.
- `fsrs_weights` — array of FSRS weights for advanced tuning.

```ruby
ActiveRecall.configure do |config|
  config.algorithm_class       = ActiveRecall::FSRS
  config.fsrs_request_retention = 0.85
  config.fsrs_maximum_interval  = 365
end
```

## Usage with binary algorithms

Applies to `LeitnerSystem`, `SoftLeitnerSystem`, and `FibonacciSequence`.

```ruby
# Initially adding a word
user.words << word
user.words.untested #=> [word]

# Guessing a word correctly
user.right_answer_for!(word)
user.words.known #=> [word]

# Guessing a word incorrectly
user.wrong_answer_for!(word)
user.words.failed #=> [word]

# Listing all words
user.words #=> [word]
```

As time passes, words need to be reviewed to keep them fresh in memory:

```ruby
# Three days later...
user.words.known   #=> []
user.words.expired #=> [word]
```

Guessing a word correctly several times in a row makes the word take longer to expire, demonstrating mastery:

```ruby
user.right_answer_for!(word)
# One week later...
user.words.expired #=> [word]
user.right_answer_for!(word)
# Two weeks later...
user.words.expired #=> [word]
user.right_answer_for!(word)
# One month later...
user.words.expired #=> [word]
```

## Usage with SM2

[SM2](https://en.wikipedia.org/wiki/SuperMemo#Description_of_SM-2_algorithm) uses a 0–5 grade scale:

| Grade | Meaning |
|---|---|
| `5` | Perfect response |
| `4` | Correct response after a hesitation |
| `3` | Correct response recalled with serious difficulty |
| `2` | Incorrect response, but close |
| `1` | Incorrect response with familiarity |
| `0` | Complete blackout |

Grades **≥ 3** count as a success: the box advances and `times_right` increments. Grades **< 3** reset the box to `0` and increment `times_wrong`. Each item's `easiness_factor` starts at `2.5` and is clamped to a minimum of `1.3`.

```ruby
user.words << word

user.score!(5, word)  # perfect recall — box advances, EF rises
user.score!(2, word)  # incorrect — box resets to 0
```

Calling `user.right_answer_for!(word)` while SM2 is configured raises `ActiveRecall::IncompatibleAlgorithmError` — use `score!` instead.

## Usage with FSRS

[FSRS](https://github.com/open-spaced-repetition/fsrs4anki) uses a 1–4 grade scale matching the familiar Anki buttons:

| Grade | Meaning |
|---|---|
| `1` | Again (lapse) |
| `2` | Hard |
| `3` | Good |
| `4` | Easy |

FSRS tracks `stability`, `difficulty`, `state`, and `lapses` per item. Those columns are added automatically by `rails generate active_recall` — no extra setup needed.

```ruby
user.words << word

user.score!(3, word)  # "Good" — typical successful recall
user.score!(1, word)  # "Again" — counts as a lapse
```

Calling `user.right_answer_for!(word)` while FSRS is configured raises `ActiveRecall::IncompatibleAlgorithmError` — use `score!` instead.

## Reviewing

In addition to the `expired` scope, ActiveRecall provides a suggested reviewing sequence for all unknown words in the deck. Words are randomly chosen from `untested`, `failed`, and `expired` items, in that order of precedence. This works the same for every algorithm.

```ruby
user.words.review #=> [word]
user.right_answer_for!(word)
# ... continuing until all untested, failed, and expired words have been guessed correctly.
user.words.review #=> []
```

You can also just get the next word to review:

```ruby
user.words.next #=> word
user.right_answer_for!(word)
# ... continuing until all untested, failed, and expired words have been guessed correctly.
user.words.next #=> nil
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `bin/spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jaysonvirissimo/active_recall.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
