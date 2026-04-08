# frozen_string_literal: true

require "fileutils"

module Sidenotes
  class Generator
    attr_reader :models_generated, :models_skipped

    def initialize
      @models_generated = []
      @models_skipped = []
    end

    def generate_all
      discover_models.each { |model| generate_for(model) }
      self
    end

    def generate_for(model)
      model = resolve_model(model)
      inspector = ModelInspector.new(model)

      unless inspector.inspectable?
        @models_skipped << model.name
        return nil
      end

      data = inspector.inspect_model
      return nil unless data

      output = Formatter.new(model.name, data).render
      path = write_file(model, output)
      @models_generated << model.name
      path
    end

    def clean
      dir = Sidenotes.configuration.output_directory
      return unless File.directory?(dir)

      ext = Sidenotes.configuration.file_extension
      Dir.glob(File.join(dir, "**", "*.#{ext}")).each { |f| File.delete(f) }

      # Remove empty directories
      Dir.glob(File.join(dir, "**", "*")).sort.reverse_each do |d|
        Dir.rmdir(d) if File.directory?(d) && Dir.empty?(d)
      end

      Dir.rmdir(dir) if File.directory?(dir) && Dir.empty?(dir)
    end

    def discover_models
      load_model_files
      collect_models
    end

    private

    def resolve_model(model)
      return model if model.is_a?(Class)

      model.to_s.constantize
    end

    def load_model_files
      config = Sidenotes.configuration

      config.model_paths.each do |path|
        full_path = Rails.root.join(path) if defined?(Rails)
        full_path ||= Pathname.new(path)

        Dir.glob(full_path.join("**", "*.rb")).sort.each do |file|
          require_dependency(file) if defined?(require_dependency)
        end
      end
    rescue StandardError
      # Models may already be loaded in eager-loaded environments
      nil
    end

    def collect_models
      models = ActiveRecord::Base.descendants.select do |model|
        next false if model.abstract_class?
        next false if excluded?(model)

        true
      end

      models.sort_by(&:name)
    end

    def excluded?(model)
      config = Sidenotes.configuration
      config.exclude_patterns.any? do |pattern|
        case pattern
        when Regexp then model.name.match?(pattern)
        when String then model.name == pattern || model.name.match?(Regexp.new(pattern))
        else false
        end
      end
    end

    def write_file(model, content)
      config = Sidenotes.configuration
      relative_path = model_to_path(model)
      file_path = File.join(config.output_directory, "#{relative_path}.#{config.file_extension}")

      FileUtils.mkdir_p(File.dirname(file_path))
      File.write(file_path, content)
      file_path
    end

    def model_to_path(model)
      # Admin::User => admin/user
      model.name.underscore
    end
  end
end
