# frozen_string_literal: true

module Fileverse
  class Error < StandardError; end

  # File not found error
  class FileNotFoundError < StandardError
    def initialize(file)
      super("Error:   Could not find file: #{file}")
    end
  end

  # Error for corrupt config file
  class CorruptFormat < StandardError
    def initialize(section = nil)
      super("Error:   The configuration file is corrupt.#{section}")
    end
  end

  # Error for negative cursor
  class NegativeCursorPointer < StandardError
    def initialize
      super("Error:  Cursor can not be negative.")
    end
  end

  # Error for maximum cursor
  class MaxCursorPointer < StandardError
    def initialize
      super("Error:  Cursor can not be larger that snapped length.")
    end
  end

  # Error for maximum cursor
  class NoContentForName < StandardError
    def initialize(name)
      super("Error:   No snapshot content for name: '#{name}'.")
    end
  end
end
