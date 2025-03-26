# frozen_string_literal: true

require "thor"

module Fileverse
  # CLI class
  class CLI < Thor
    desc "new file template", "generate a interface for file"
    def new(path)
      full_path = Fileverse::Files.expanded_path(path)
      full_hidden_path = Fileverse::Files.expanded_hidden_path(full_path)
      Fileverse::Files.create_hidden_file(full_hidden_path)
      # p Fileverse::Files.create_hidden_file file_path
    end
  end
end
