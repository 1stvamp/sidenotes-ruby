# frozen_string_literal: true

require_relative "sidenotes/version"
require_relative "sidenotes/configuration"
require_relative "sidenotes/model_inspector"
require_relative "sidenotes/formatter"
require_relative "sidenotes/generator"

module Sidenotes
  class Error < StandardError; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end

require_relative "sidenotes/railtie" if defined?(Rails::Railtie)
