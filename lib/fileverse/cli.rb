# frozen_string_literal: true

require "thor"

module Fileverse
  # CLI class
  class CLI < Thor # rubocop:disable Metrics/ClassLength
    desc "snap file content", "store current file content"
    options template: :boolean, name: :string, clear: :boolean
    def snap(path)
      setup_options
      @template ? setup_template_parser(path) : setup_file_parser(path)
      @parser.add_snapshot(Files.read(@path), @snapshot_name)
      Files.clear_content(@path) if @clear
      Files.write_content(@storage_path, @parser.to_writable_lines)
      puts "snapped#{@clear ? " and cleared" : ""}."
    rescue StandardError => e
      puts e.message
    end
    map "s" => "snap"

    desc "restore content", "restore content in the current cursor"
    options template: :boolean, name: :string
    def restore(path)
      setup_options
      @template ? restore_template_snapshot(path) : restore_file_snapshot(path)
      puts "#{@snapshot_name || "snapshot at cursor index"} for #{@template ? "template" : "file"} restored."
    rescue StandardError => e
      puts e.message
    end
    map "r" => "restore"

    desc "preview snapshot", "preview snapshot at different index or name"
    options bwd: :boolean, fwd: :boolean, index: :numeric, name: :string, template: :boolean
    def preview(path)
      setup_options
      @template ? setup_template_parser(path) : setup_file_parser(path)
      setup_previewer
      @previewer.preview_content = preview_content
      Files.write_content(@path, @previewer.to_writable_lines)
      Files.write_content(@storage_path, @parser.to_writable_lines)
    rescue StandardError => e
      puts e.message
    end
    map "p" => "preview"

    desc "reset", "reset files. both the storage and original"
    def reset(path)
      setup_file_parser(path)
      @parser.reset
      setup_previewer
      @previewer.parse
      @previewer.preview_content = []
      Files.write_content(@path, @previewer.to_writable_lines)
      Files.write_content(@storage_path, @parser.to_writable_lines)
      puts "storage reset."
    rescue StandardError => e
      puts e.message
    end
    map "x" => "reset"

    desc "snap restore", "snap and restore template"
    options template_name: :string
    def snap_and_restore_template(path)
      snap path
      @snapshot_name = @template_name
      Files.clear_content path
      restore_template_snapshot path
      puts "And restored template '#{@template_name}'."
    rescue StandardError => e
      puts e.message
    end
    map "sart" => "snap_and_restore_template"

    private

    def setup_file_parser(path)
      @path = Files.expand_path(path)
      @storage_path = Files.expand_hidden_path(path)
      @parser = Parser.new(@storage_path)
      @parser.parse
    end

    def setup_template_parser(path)
      @path = Files.expand_path(path)
      @storage_path = Files.template_path
      @parser = Parser.new(@storage_path)
      @parser.parse
    end

    def setup_previewer
      @previewer = Previewer.new(@path)
      @previewer.parse
    end

    def setup_options
      @template = options[:template]
      @snapshot_name = options[:name]
      @move_backward = options[:bwd]
      @move_forward = options[:fwd]
      @index = options[:index]
      @clear = options[:clear]
      @template_name = options[:template_name]
    end

    def restore_file_snapshot(path)
      setup_file_parser(path)
      Files.write_content(@path, @parser.cursor_content)
      @parser.remove_cursor_snapshot
      Files.write_content(@storage_path, @parser.to_writable_lines)
    end

    def restore_template_snapshot(path)
      setup_template_parser(path)
      Files.write_content(@path, @parser.snapshot_content_by_name(@snapshot_name))
    end

    def preview_content # rubocop:disable Metrics/MethodLength
      if @snapshot_name
        @parser.snapshot_content_by_name(options[:name])
      elsif @move_backward
        @parser.snapshot_content_backward
      elsif @move_forward
        @parser.snapshot_content_forward
      elsif @index
        @parser.snapshot_content_by_index(options[:index])
      else
        @parser.cursor_content
      end
    end
  end
end
