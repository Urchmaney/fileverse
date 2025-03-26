# frozen_string_literal: true

module Fileverse
  module Files # rubocop:disable Style/Documentation
    module_function

    def expanded_path(path)
      path = File.expand_path path, Dir.pwd
      throw Fileverse::FileNotFoundError.new(file_path) unless File.exist? path
      path
    end

    def expanded_hidden_path(path)
      path = File.join(File.dirname(path), ".verse.#{File.basename(path)}")
      File.expand_path path, Dir.pwd
    end

    def create_hidden_file(path)
      File.open(path, "w") do |writer|
        writer.write(inital_header)
      end
    end

    def inital_header
      <<~INITIAL_HEADER
        ######0
        ######>
      INITIAL_HEADER
    end
  end
end
