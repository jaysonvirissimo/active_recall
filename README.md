# ActiveRecall [![Build Status](https://travis-ci.org/jaysonvirissimo/active_recall.svg?branch=master)](https://travis-ci.org/jaysonvirissimo/active_recall)

**ActiveRecall** is a spaced-repetition system that allows you to treat arbitrary [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord) models as if they were flashcards to be learned and reviewed.
It it based on, and is intended to be backwards compatible with, the [okubo](https://github.com/rgravina/okubo) gem.
The primary differentiating features are that it lets the user specify the scheduling algorithm and is fully compatible with (and requires at least) Rails 6.0.

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

## Usage
You can configure the desired SRS algorithm during runtime:
```ruby
ActiveRecall.configure do |config|
  config.algorithm_class = ActiveRecall::FibonacciSequence
end
```
For Rails applications, try doing this from within an [initializer file](https://guides.rubyonrails.org/configuring.html#using-initializer-files).

Assume you have an application allowing your users to study words in a foreign language. Using the `has_deck` method you can set up a deck of flashcards that the user will study:

```ruby
class Word < ActiveRecord::Base
end

class User < ActiveRecord::Base
  has_deck :words
end

user = User.create!(:name => "Robert")
word = Word.create!(:kanji => "日本語", :kana => "にほんご", :translation => "Japanese language")
```

You can add words and record attempts to guess the word as right or wrong. Various methods exist to allow you to access subsets of this collection:

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
user.words.known #=> []
user.words.expired #=> [word]
```

Guessing a word correctly several times in a row results in the word taking longer to expire, and demonstrates mastery of that word.

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

Reviewing
---------

In addition to an `expired` method, ActiveRecall provides a suggested reviewing sequence for all unknown words in the deck.
Words are randomly chosen from all untested words, failed, and finally expired in order of precedence.

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

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jaysonvirissimo/active_recall.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
