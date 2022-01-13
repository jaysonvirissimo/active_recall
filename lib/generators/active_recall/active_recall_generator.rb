# frozen_string_literal: true

require "rails/generators"
require "rails/generators/migration"
require "rails/generators/active_record"

class ActiveRecallGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  class_option :migrate_data, type: :boolean, default: false

  desc "Creates migration files required by the active_recall spaced repetition gem."

  source_paths << File.join(File.dirname(__FILE__), "templates")

  def self.next_migration_number(path)
    ActiveRecord::Generators::Base.next_migration_number(path)
  end

  def create_migration_files
    create_migration_file_if_not_exist "create_active_recall_tables"
    create_migration_file_if_not_exist "add_active_recall_item_answer_counts"
    create_migration_file_if_not_exist "migrate_okubo_to_active_recall" if options["migrate_data"]
  end

  private

  def create_migration_file_if_not_exist(file_name)
    unless self.class.migration_exists?(File.dirname(File.expand_path("db/migrate/#{file_name}")), file_name)
      migration_template "#{file_name}.rb", "db/migrate/#{file_name}.rb"
    end
  end
end
