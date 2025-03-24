# frozen_string_literal: true

require "thor"

module Fileverse
  # CLI class
  class CLI < Thor
    desc "welcome", "A warm welcoming message"
    def welcome
      p "welcome"
    end
  end
end
