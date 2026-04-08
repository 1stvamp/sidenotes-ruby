# frozen_string_literal: true

require_relative "lib/sidenotes/version"

Gem::Specification.new do |spec|
  spec.name = "sidenotes"
  spec.version = Sidenotes::VERSION
  spec.authors = ["Wes Mason"]
  spec.email = ["wesley.mason@pinpointhq.com"]

  spec.summary = "Structured YAML/JSON schema annotations for Rails models as sidecar files"
  spec.description = "Generates structured schema annotation files for Rails models as gitignored " \
                     "sidecar files, replacing inline comments with separate metadata files that " \
                     "IDEs and tools can consume."
  spec.homepage = "https://github.com/wesmason/sidenotes"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/wesmason/sidenotes"
  spec.metadata["changelog_uri"] = "https://github.com/wesmason/sidenotes/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 6.1"
  spec.add_dependency "activesupport", ">= 6.1"
  spec.add_dependency "railties", ">= 6.1"
end
