# frozen_string_literal: true

require "spec_helper"

RSpec.describe Sidenotes::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it "has default output directory" do
      expect(config.output_directory).to eq(".annotations")
    end

    it "has default format" do
      expect(config.format).to eq(:yaml)
    end

    it "has default sections" do
      expect(config.sections).to eq(%i[columns indexes associations foreign_keys metadata])
    end

    it "has default model paths" do
      expect(config.model_paths).to eq(["app/models"])
    end

    it "has empty exclude patterns" do
      expect(config.exclude_patterns).to eq([])
    end
  end

  describe "#format=" do
    it "accepts :yaml" do
      config.format = :yaml
      expect(config.format).to eq(:yaml)
    end

    it "accepts :json" do
      config.format = :json
      expect(config.format).to eq(:json)
    end

    it "converts strings to symbols" do
      config.format = "json"
      expect(config.format).to eq(:json)
    end

    it "raises on invalid format" do
      expect { config.format = :xml }.to raise_error(ArgumentError, /Invalid format/)
    end
  end

  describe "#sections=" do
    it "accepts valid sections" do
      config.sections = %i[columns indexes]
      expect(config.sections).to eq(%i[columns indexes])
    end

    it "raises on invalid sections" do
      expect { config.sections = %i[columns invalid_section] }.to raise_error(ArgumentError, /Invalid sections/)
    end

    it "converts strings to symbols" do
      config.sections = %w[columns indexes]
      expect(config.sections).to eq(%i[columns indexes])
    end
  end

  describe "#file_extension" do
    it "returns yml for yaml format" do
      config.format = :yaml
      expect(config.file_extension).to eq("yml")
    end

    it "returns json for json format" do
      config.format = :json
      expect(config.file_extension).to eq("json")
    end
  end

  describe "Sidenotes.configure" do
    it "yields configuration" do
      Sidenotes.configure do |c|
        c.output_directory = "custom_dir"
        c.format = :json
      end

      expect(Sidenotes.configuration.output_directory).to eq("custom_dir")
      expect(Sidenotes.configuration.format).to eq(:json)
    end

    it "resets configuration" do
      Sidenotes.configure { |c| c.format = :json }
      Sidenotes.reset_configuration!
      expect(Sidenotes.configuration.format).to eq(:yaml)
    end
  end
end
