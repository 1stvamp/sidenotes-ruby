# frozen_string_literal: true

require "spec_helper"

RSpec.describe Sidenotes::Generator do
  subject(:generator) { described_class.new }

  describe "#generate_for" do
    it "generates a YAML file for a model class" do
      path = generator.generate_for(User)
      expect(path).to end_with("user.yml")
      expect(File.exist?(path)).to be true
    end

    it "writes valid YAML content" do
      path = generator.generate_for(User)
      content = File.read(path)
      yaml_content = content.lines.reject { |l| l.start_with?("#") }.join
      parsed = YAML.safe_load(yaml_content)
      expect(parsed["User"]["metadata"]["table_name"]).to eq("users")
    end

    it "creates output directory if missing" do
      Sidenotes.configure { |c| c.output_directory = "custom_annotations" }
      generator.generate_for(User)
      expect(Dir.exist?("custom_annotations")).to be true
    end

    it "generates JSON when configured" do
      Sidenotes.configure { |c| c.format = :json }
      path = generator.generate_for(User)
      expect(path).to end_with("user.json")

      parsed = JSON.parse(File.read(path))
      expect(parsed["User"]).to be_a(Hash)
    end

    it "accepts model name as string" do
      path = generator.generate_for("User")
      expect(path).to end_with("user.yml")
      expect(File.exist?(path)).to be true
    end

    it "handles STI subclasses" do
      path = generator.generate_for(AdminUser)
      expect(path).to end_with("admin_user.yml")
      expect(File.exist?(path)).to be true
    end

    it "tracks generated models" do
      generator.generate_for(User)
      expect(generator.models_generated).to include("User")
    end

    it "skips abstract classes and tracks them" do
      result = generator.generate_for(ApplicationRecord)
      expect(result).to be_nil
      expect(generator.models_skipped).to include("ApplicationRecord")
    end
  end

  describe "#generate_all" do
    it "generates files for all discoverable models" do
      generator.generate_all
      expect(generator.models_generated).not_to be_empty
    end

    it "includes User model" do
      generator.generate_all
      expect(generator.models_generated).to include("User")
    end

    it "includes Post model" do
      generator.generate_all
      expect(generator.models_generated).to include("Post")
    end

    it "creates files in the output directory" do
      generator.generate_all
      dir = Sidenotes.configuration.output_directory
      expect(Dir.glob(File.join(dir, "**", "*.yml"))).not_to be_empty
    end
  end

  describe "#clean" do
    before do
      generator.generate_for(User)
      generator.generate_for(Post)
    end

    it "removes all generated annotation files" do
      dir = Sidenotes.configuration.output_directory
      expect(Dir.glob(File.join(dir, "**", "*.yml"))).not_to be_empty

      generator.clean
      expect(Dir.glob(File.join(dir, "**", "*.yml"))).to be_empty
    end

    it "removes empty directories" do
      dir = Sidenotes.configuration.output_directory
      generator.clean
      expect(Dir.exist?(dir)).to be false
    end
  end

  describe "#discover_models" do
    it "returns an array of model classes" do
      models = generator.discover_models
      expect(models).to all(be < ActiveRecord::Base)
    end

    it "excludes abstract classes" do
      models = generator.discover_models
      expect(models).not_to include(ApplicationRecord)
    end

    it "sorts models by name" do
      models = generator.discover_models
      names = models.map(&:name)
      expect(names).to eq(names.sort)
    end

    it "respects exclude patterns" do
      Sidenotes.configure { |c| c.exclude_patterns = ["AdminUser"] }
      models = generator.discover_models
      expect(models.map(&:name)).not_to include("AdminUser")
    end

    it "respects regexp exclude patterns" do
      Sidenotes.configure { |c| c.exclude_patterns = [/^Admin/] }
      models = generator.discover_models
      admin_models = models.select { |m| m.name.start_with?("Admin") }
      expect(admin_models).to be_empty
    end
  end
end
