# frozen_string_literal: true

module Fileverse
  module Files # rubocop:disable Style/Documentation
    def self.find(file_path)
      path = File.expand_path file_path, Dir.pwd
      throw Fileverse::FileNotFoundError.new(file_path) unless File.exist? path
    end
  end
end
