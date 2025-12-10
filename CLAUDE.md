# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ActiveRecall is a Ruby gem that implements a spaced-repetition system (SRS) for ActiveRecord models. It allows treating arbitrary ActiveRecord models as flashcards with configurable scheduling algorithms. The gem is backwards-compatible with the okubo gem and requires Rails 6+ and Ruby 3+.

## Common Commands

### Testing
```bash
# Run all tests (PREFERRED - handles appraisal automatically)
bin/spec

# Run tests against a specific Rails version
bin/spec rails-7-0
bin/spec rails-7-1
bin/spec rails-8-0

# Note: Direct bundle exec commands may encounter sqlite3 version conflicts
# The bin/spec wrapper handles this by using the appropriate appraisal gemfiles
```

### Linting
```bash
# Run StandardRB linter
bin/lint
# or
bundle exec standardrb

# Auto-fix issues
bundle exec standardrb --fix
```

### Development Setup
```bash
# Install dependencies and set up database
bin/setup

# Launch interactive console
bin/console
```

### Testing Against Multiple Rails Versions
```bash
# Generate gemfiles for different Rails versions (run after Gemfile changes)
bundle exec appraisal install

# Run tests against specific Rails version manually
bundle exec appraisal rails-7-0 rake spec
bundle exec appraisal rails-7-1 rake spec
bundle exec appraisal rails-8-0 rake spec

# Note: bin/spec runs tests against all Rails versions automatically
# This is defined in the Appraisals file and creates separate gemfiles in gemfiles/
```

### Gem Management
```bash
# Build the gem
bundle exec rake build

# Install gem locally
bundle exec rake install

# Release new version (requires updating lib/active_recall/version.rb first)
bundle exec rake release
```

## Architecture

### Core Components

1. **ActiveRecall::Base** (lib/active_recall/base.rb)
   - Provides `has_deck` class method that makes any ActiveRecord model a deck owner
   - Mixes in DeckMethods and ItemMethods when invoked
   - Sets up polymorphic relationship between users and their decks

2. **ActiveRecall::Deck** (lib/active_recall/models/deck.rb)
   - Polymorphic model representing a collection of items to review
   - Belongs to a user (polymorphic), has many items
   - Key methods: `review`, `next`, `untested`, `failed`, `known`, `expired`, `box(n)`
   - Handles database adapter differences (MySQL vs others) for random ordering

3. **ActiveRecall::Item** (lib/active_recall/models/item.rb)
   - Represents individual flashcard items in a deck
   - Polymorphic association to source objects (the actual flashcard content)
   - Methods: `score!(grade)`, `right!`, `wrong!`
   - Delegates to configured algorithm for calculating next review dates

4. **Algorithms** (lib/active_recall/algorithms/)
   - Each algorithm class implements: `type`, `required_attributes`, `right`, `wrong`, and optionally `score`
   - Algorithm types: `:binary` (right/wrong only) or `:gradable` (accepts scores)
   - Binary algorithms: LeitnerSystem (default), SoftLeitnerSystem, FibonacciSequence
   - Gradable algorithm: SM2
   - All algorithms are stateless; they accept current state and return new state as a hash

5. **Configuration** (lib/active_recall/configuration.rb)
   - Global configuration via `ActiveRecall.configure`
   - Primary setting: `algorithm_class` (defaults to LeitnerSystem)
   - Configuration should be set in Rails initializers

### Data Flow

1. A model calls `has_deck :items_name` to enable SRS functionality
2. This creates a Deck record (polymorphic, user_id/user_type)
3. Items are added to deck with `<<` operator, creating Item records
4. Item records store: box number, review dates, times_right/times_wrong, easiness_factor (for SM2)
5. User calls `right_answer_for!(item)` or `wrong_answer_for!(item)` (or `score!(grade, item)` for gradable algorithms)
6. This delegates to Item's `right!`/`wrong!`/`score!` which calls the configured algorithm
7. Algorithm returns hash of updated attributes (box, next_review, etc.)
8. Deck provides query methods that filter items by state and return source objects

### Key Design Patterns

- **Polymorphic associations**: Decks belong to any "user" model, Items reference any "source" model
- **Strategy pattern**: Algorithms are swappable via configuration
- **Delegation**: Deck methods delegate to Item scopes, which use the configured algorithm
- **Stateless algorithms**: All algorithm classes are stateless with class methods only (except FibonacciSequence which caches Fibonacci numbers in instances)

## Database Schema

The gem creates two tables via generators:
- `active_recall_decks`: id, user_id (polymorphic), user_type, created_at, updated_at
- `active_recall_items`: id, deck_id, source_id (polymorphic), source_type, box, times_right, times_wrong, last_reviewed, next_review, easiness_factor, created_at, updated_at

## Migration from Okubo

The gem includes a migration template (`migrate_okubo_to_active_recall.rb`) that renames tables from okubo_* to active_recall_*. Use `rails generate active_recall --migrate_data true` to generate this migration.

## Code Style

- Uses StandardRB for linting (config in standard.yml)
- All files have `# frozen_string_literal: true` pragma
- Ruby 3.2+ syntax required

## Testing Conventions

### Test File Structure
- Spec files mirror lib/ directory structure (e.g., `lib/active_recall/foo.rb` → `spec/active_recall/foo_spec.rb`)
- All spec files start with `# frozen_string_literal: true` and `require "spec_helper"`
- Use `describe ClassName` for top-level blocks
- Use `context` blocks to organize different scenarios
- Use `subject { described_class.new }` for the class under test

### Common Patterns
```ruby
# Basic structure
describe ActiveRecall::SomeClass do
  subject { described_class.new }

  describe "#method_name" do
    it "describes expected behavior" do
      expect(subject.method_name).to eq(expected_value)
    end
  end

  context "when specific condition" do
    it "behaves differently" do
      # test implementation
    end
  end
end
```

### Shared Examples
- Algorithm specs use shared examples for common behavior (see spec/active_recall/algorithms/algorithm_spec.rb)
- Binary algorithms share: `it_behaves_like "binary spaced repetition algorithms"`
- This ensures consistent testing across algorithm implementations

### Test Data Setup
- Use `let` blocks for test data that needs to be created
- Use `before` blocks for setup that must run before each test
- The spec_helper.rb defines Word and User models for testing deck functionality

### Running Specific Tests
While `bin/spec` is preferred for full test runs, you can run individual specs during development:
```bash
# During active development, you may need to specify the appraisal
bundle exec appraisal rails-8-0 rspec spec/active_recall/configuration_spec.rb

# Or run all specs via bin/spec which handles all Rails versions
bin/spec
```

### Test Infrastructure Notes
- Tests use an in-memory SQLite database (`:memory:`) configured in spec/spec_helper.rb
- Different Rails versions require different sqlite3 gem versions:
  - Rails 7.0/7.1 use sqlite3 ~> 1.4
  - Rails 8.0 uses sqlite3 >= 2.1
- The appraisal system manages these version conflicts via separate gemfiles
- Always use `bin/spec` to avoid sqlite3 version conflict errors
- Direct `bundle exec rspec` commands will fail with "can't activate sqlite3" errors
