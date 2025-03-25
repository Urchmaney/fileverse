# frozen_string_literal: true

require "thor"

module Fileverse
  # CLI class
  class CLI < Thor
    desc "new file template", "generate a interface for file"
    def new(file_path)
      p Fileverse::Files.find file_path
    end
  end
end
