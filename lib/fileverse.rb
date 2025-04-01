# frozen_string_literal: true

require_relative "fileverse/version"
require_relative "fileverse/errors"
require_relative "fileverse/files"
require_relative "fileverse/parser"
require_relative "fileverse/previewer"

# Parent module
module Fileverse
  def self.create_hidden_file(path)
    File.open(path, "w") do |writer|
      writer.write(inital_header)
    end
  end
end

require_relative "fileverse/cli"
