require "spec_helper"
require "generators/active_recall/active_recall_generator"
require "fileutils"

RSpec.describe ActiveRecallGenerator, type: :generator do
  before(:context) do
    @destination_root = File.expand_path("../../tmp", __FILE__)
    prepare_destination
  end

  def prepare_destination
    FileUtils.mkdir_p(@destination_root)
    FileUtils.rm_rf(Dir.glob("#{@destination_root}/*"))
  end

  def run_generator(args = {})
    options = args.each_with_object({}) do |arg, opts|
      key, value = arg.to_s.split("=")
      opts[key.sub(/^--/, "").to_sym] = value.nil? ? true : value
    end

    gen = ActiveRecallGenerator.new([], options)
    gen.destination_root = @destination_root
    gen.invoke_all
  end

  def migration_exists?(pattern)
    Dir.glob(File.join(@destination_root, "db/migrate/#{pattern}")).any?
  end

  it "creates migration files" do
    run_generator
    expect(migration_exists?("*_create_active_recall_tables.rb")).to be_truthy
    expect(migration_exists?("*_add_active_recall_item_answer_counts.rb")).to be_truthy
    expect(migration_exists?("*_add_active_recall_item_easiness_factor.rb")).to be_truthy
  end

  context "when migration files already exist" do
    it "does not create additional migration files" do
      run_generator
      initial_migration_count = Dir[File.join(@destination_root, "db/migrate/*")].length
      run_generator
      expect(Dir[File.join(@destination_root, "db/migrate/*")].length).to eq(initial_migration_count)
    end
  end

  context "when migrate_data option is specified" do
    it "creates migration for migrating data" do
      run_generator [:migrate_data]
      expect(migration_exists?("*_migrate_okubo_to_active_recall.rb")).to be_truthy
    end
  end
end
