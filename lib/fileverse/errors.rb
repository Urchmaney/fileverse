# frozen_string_literal: true

module Fileverse
  class Error < StandardError; end

  # File not found error
  class FileNotFoundError < StandardError
    def initialize(file)
      super("Could not find file: #{file}")
    end
  end
end
