# frozen_string_literal: true

require "thor"

module Fileverse
  # CLI class
  class CLI < Thor
    desc "snap file content", "store current file content"
    def snap(path)
      setup path
      @parser.parse
      @parser.add_snapshot(Files.read(@path))
      Files.write_content(@path)
      Files.write_content(@hidden_path, @parser.to_writable_lines)
    end
    map "s" => "snap"

    desc "restore content", "restore content in the current cursor"
    def restore(path)
      setup path
      @parser.parse
      Files.write_content(@path, @parser.cursor_content)
      @parser.remove_cursor_snapshot
      Files.write_content(@hidden_path, @parser.to_writable_lines)
    end
    map "r" => "restore"

    desc "preview snapshot", "preview snapshot at different index or name"
    options bwd: :boolean, fwd: :boolean, index: :numeric, name: :string
    def preview(path)
      setup path
      @parser.parse
      @previewer.parse
      update_preview_content
      Files.write_content(@path, @previewer.to_writable_lines)
      Files.write_content(@hidden_path, @parser.to_writable_lines)
    end
    map "p" => "preview"

    desc "reset", "reset files. both the config and original"
    def reset(path)
      setup path
      @parser.parse
      @previewer.parse
      @previewer.preview_content = []
      @parser.reset
      Files.write_content(@path, @previewer.to_writable_lines)
      Files.write_content(@hidden_path, @parser.to_writable_lines)
    end
    map "x" => "reset"

    desc "summary", "return all the summary of snapshots"
    def summary(path)
      setup path
      @parser.parse_head
      puts @parser.summary
    end
    map "sm" => "summary"

    private

    def setup(path)
      @path = Files.expand_path(path)
      @hidden_path = Files.expand_hidden_path(path)
      @parser = Parser::Header.new(@hidden_path)
      @previewer = Previewer.new(@path)
    end

    def update_preview_content
      if options[:bwd]
        @parser.decrement_cursor
      elsif options[:fwd]
        @parser.increment_cursor
      elsif options[:index]
        @parser.cursor = options[:index]
      end
      @previewer.preview_content = @parser.cursor_content
    end
  end
end
