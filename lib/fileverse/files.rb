# frozen_string_literal: true

module Fileverse
  module Files # rubocop:disable Style/Documentation
    module_function

    def expand_path(path)
      File.expand_path path, Dir.pwd
    end

    def expand_hidden_path(path)
      path = File.join(File.dirname(path), ".verse.#{File.basename(path)}")
      File.expand_path path, Dir.pwd
    end

    def read(path)
      full_path = File.expand_path path, Dir.pwd
      File.readlines(full_path)
    end

    def write_content(path, content = [])
      full_path = File.expand_path path, Dir.pwd
      File.open(full_path, "w") { |file| file.puts content }
    end
  end
end
