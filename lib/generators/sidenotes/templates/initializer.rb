# frozen_string_literal: true

Sidenotes.configure do |config|
  # Directory where annotation files are generated (relative to Rails root)
  # config.output_directory = ".annotations"

  # Output format: :yaml (default) or :json
  # config.format = :yaml

  # Sections to include in annotations
  # Available: :columns, :indexes, :associations, :foreign_keys, :check_constraints, :triggers, :metadata
  # config.sections = %i[columns indexes associations foreign_keys metadata]

  # Paths to search for model files (relative to Rails root)
  # config.model_paths = ["app/models"]

  # Patterns to exclude models (strings or regexps)
  # config.exclude_patterns = ["ApplicationRecord", /^HABTM_/]
end
