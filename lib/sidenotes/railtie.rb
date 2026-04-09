# frozen_string_literal: true

module Sidenotes
  class Railtie < Rails::Railtie
    rake_tasks do
      namespace :sidenotes do
        desc 'Generate annotation files for all models'
        task generate: :environment do
          Sidenotes::Railtie.run_generate
        end

        desc 'Remove all annotation files'
        task clean: :environment do
          Sidenotes::Generator.new.clean
          puts "Sidenotes: Cleaned annotation files from #{Sidenotes.configuration.output_directory}"
        end

        desc 'Generate annotation for a single model (MODEL=User)'
        task model: :environment do
          Sidenotes::Railtie.run_model
        end
      end
    end

    def self.run_generate
      generator = Sidenotes::Generator.new
      generator.generate_all

      puts "Sidenotes: Generated #{generator.models_generated.size} annotation(s)"
      generator.models_generated.each { |m| puts "  #{m}" }

      return unless generator.models_skipped.any?

      puts "Skipped #{generator.models_skipped.size} model(s):"
      generator.models_skipped.each { |m| puts "  #{m} (skipped)" }
    end

    def self.run_model
      model_name = ENV.fetch('MODEL', nil)
      abort 'Usage: rake sidenotes:model MODEL=User' unless model_name

      generator = Sidenotes::Generator.new
      path = generator.generate_for(model_name)

      if path
        puts "Sidenotes: Generated #{path}"
      else
        puts "Sidenotes: Could not generate annotation for #{model_name}"
      end
    end
  end
end
