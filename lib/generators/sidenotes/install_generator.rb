# frozen_string_literal: true

require "rails/generators"

module Sidenotes
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates a Sidenotes initializer and adds .annotations/ to .gitignore"

      def copy_initializer
        template "initializer.rb", "config/initializers/sidenotes.rb"
      end

      def add_to_gitignore
        gitignore = File.join(destination_root, ".gitignore")
        if File.exist?(gitignore)
          content = File.read(gitignore)
          unless content.include?(".annotations/")
            append_to_file ".gitignore", "\n# Sidenotes schema annotations\n.annotations/\n"
          end
        end
      end
    end
  end
end
