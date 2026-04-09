# frozen_string_literal: true

require 'rails/generators'

module Sidenotes
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      class_option :gitignore, type: :boolean, default: true,
                               desc: 'Add .annotations/ to .gitignore'

      desc 'Creates an optional Sidenotes initializer for customising configuration'

      def copy_initializer
        template 'initializer.rb', 'config/initializers/sidenotes.rb'
      end

      def add_to_gitignore
        return unless options[:gitignore]

        gitignore = File.join(destination_root, '.gitignore')
        return unless File.exist?(gitignore)

        content = File.read(gitignore)
        return if content.include?('.annotations/')

        append_to_file '.gitignore', "\n# Sidenotes schema annotations\n.annotations/\n"
      end
    end
  end
end
