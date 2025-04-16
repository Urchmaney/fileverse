# frozen_string_literal: true

require "thor"

module Fileverse
  # CLI class
  class CLI < Thor
    desc "snap file content", "store current file content"
    options template: :boolean, name: :string
    def snap(path)
      setup path
      @parser.parse
      @parser.add_snapshot(Files.read(@path), options[:name])
      Files.write_content(@path)
      Files.write_content(@hidden_path, @parser.to_writable_lines)
    end
    map "s" => "snap"

    desc "restore content", "restore content in the current cursor"
    options template: :boolean, name: :string
    def restore(path)
      setup path
      @parser.parse
      options[:template] ? restore_template : restore_snapshot
    end
    map "r" => "restore"

    desc "preview snapshot", "preview snapshot at different index or name"
    options bwd: :boolean, fwd: :boolean, index: :numeric, name: :string, template: :boolean
    def preview(path)
      setup path
      @parser.parse
      @previewer.parse
      @previewer.preview_content = preview_content
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
      @hidden_path = options[:template] ? Files.template_path : Files.expand_hidden_path(path)
      @parser = Parser.new(@hidden_path)
      @previewer = Previewer.new(@path)
    end

    def restore_snapshot
      Files.write_content(@path, @parser.cursor_content)
      @parser.remove_cursor_snapshot
      Files.write_content(@hidden_path, @parser.to_writable_lines)
    end

    def restore_template
      template_content = @parser.snapshot_content_by_name(options[:name])
      return if template_content.nil?

      Files.write_content(@path, template_content)
    end

    def preview_content
      if options[:name]
        @parser.snapshot_content_by_name(options[:name])
      elsif options[:bwd]
        @parser.snapshot_content_backward
      elsif options[:fwd]
        @parser.snapshot_content_forward
      elsif options[:index]
        @parser.snapshot_content_by_index(options[:index])
      end
    end
  end
end
