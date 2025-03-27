# frozen_string_literal: true

module Fileverse
  module Files # rubocop:disable Style/Documentation
    module_function

    def expand_path(path)
      path = File.expand_path path, Dir.pwd
      raise Fileverse::FileNotFoundError, path unless File.exist? path

      path
    end

    def expand_hidden_path(path)
      path = File.join(File.dirname(path), ".verse.#{File.basename(path)}")
      File.expand_path path, Dir.pwd
    end

    def read(path)
      full_path = expand_path(path)
      File.read(full_path)
    end
  end
end
