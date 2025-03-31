# frozen_string_literal: true

require "thor"

module Fileverse
  # CLI class
  class CLI < Thor
    desc "snap file content", "store current file content"
    def snap(path)
      parser, full_hidden_path = parser_and_hidden_path path
      parser.parse
      parser.add_snapshot(Files.read(path))
      Files.wrie_content(path)
      Files.wrie_content(full_hidden_path, parser.to_writable_lines)
    end
    map "s" => "snap"

    desc "restore content", "restore content in the current cursor"
    def restore(path)
      parser, full_hidden_path = parser_and_hidden_path path
      parser.parse
      Files.wrie_content(path, parser.cursor_content)
      parser.remove_cursor_snapshot
      Files.wrie_content(full_hidden_path, parser.to_writable_lines)
    end
    map "r" => "restore"

    private

    def parser_and_hidden_path(path)
      full_hidden_path = Files.expand_hidden_path(path)
      parser = Parser::Header.new(full_hidden_path)
      [parser, full_hidden_path]
    end
  end
end
