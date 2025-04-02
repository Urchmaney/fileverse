# frozen_string_literal: true

module Fileverse
  class Error < StandardError; end

  # File not found error
  class FileNotFoundError < StandardError
    def initialize(file)
      super("Could not find file: #{file}")
    end
  end

  # Error for corrupt config file
  class CorruptFormat < StandardError
    def initialize(section = nil)
      super("The configuration file is corrupt.#{section}")
    end
  end

  # Error for invalid cursor
  class InvalidCursorPointer < StandardError
    def initialize(section = nil)
      super("Invalid cursor.#{section}")
    end
  end
end
