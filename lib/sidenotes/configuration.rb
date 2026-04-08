# frozen_string_literal: true

module Sidenotes
  class Configuration
    VALID_FORMATS = %i[yaml json].freeze
    VALID_SECTIONS = %i[columns indexes associations foreign_keys check_constraints triggers metadata].freeze
    DEFAULT_SECTIONS = %i[columns indexes associations foreign_keys metadata].freeze

    attr_accessor :output_directory, :format, :sections, :model_paths, :exclude_patterns, :include_triggers

    def initialize
      @output_directory = ".annotations"
      @format = :yaml
      @sections = DEFAULT_SECTIONS.dup
      @model_paths = ["app/models"]
      @exclude_patterns = []
      @include_triggers = false
    end

    def format=(value)
      value = value.to_sym
      unless VALID_FORMATS.include?(value)
        raise ArgumentError, "Invalid format: #{value}. Valid formats: #{VALID_FORMATS.join(', ')}"
      end

      @format = value
    end

    def sections=(value)
      value = Array(value).map(&:to_sym)
      invalid = value - VALID_SECTIONS
      unless invalid.empty?
        raise ArgumentError, "Invalid sections: #{invalid.join(', ')}. Valid sections: #{VALID_SECTIONS.join(', ')}"
      end

      @sections = value
    end

    def output_directory=(value)
      @output_directory = value.to_s
    end

    def file_extension
      case @format
      when :yaml then "yml"
      when :json then "json"
      end
    end
  end
end
