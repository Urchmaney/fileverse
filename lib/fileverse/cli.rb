# frozen_string_literal: true

require "thor"
require_relative "captain"

module Fileverse
  # CLI class
  class CLI < Thor
    desc "snap file content", "store current file content"
    options template: :boolean, name: :string, clear: :boolean
    def snap(path)
      setup path
      if @template
        @captain.snap_content_to_template_storage(@snapshot_name)
      else
        @captain.snap_content_to_file_storage(@snapshot_name)
      end
      @captain.clear_file_content if @clear
      @template ? @captain.save_template_storage : @captain.save_file_storage
    rescue StandardError => e
      puts e.message
    end
    map "s" => "snap"

    desc "restore content", "restore content in the current cursor"
    options template: :boolean, name: :string
    def restore(path)
      setup path
      if @template
        @captain.restore_template_snapshot(@snapshot_name)
      else
        @captain.restore_file_snapshot(remove_snapshot: true)
      end
      puts "#{@snapshot_name || "snapshot at cursor index"} for #{@template ? "template" : "file"} restored."
    rescue StandardError => e
      puts e.message
    end
    map "r" => "restore"

    desc "preview snapshot", "preview snapshot at different index or name"
    options bwd: :boolean, fwd: :boolean, index: :numeric, name: :string, template: :boolean
    def preview(path) # rubocop:disable Metrics/MethodLength
      setup path
      if @snapshot_name
        @captain.preview_by_snap_name(@snapshot_name, is_template: @template)
      elsif @move_backward
        @captain.preview_backward(is_template: @template)
      elsif @move_forward
        @captain.preview_forward(is_template: @template)
      elsif @index
        @captain.preview_by_snap_index(@index, is_template: @template)
      else
        @captain.preview_current_snapshot(is_template: @template)
      end
    rescue StandardError => e
      puts e.message
    end
    map "p" => "preview"

    desc "reset", "reset files. both the storage and original"
    def reset(path)
      setup path
      @captain.reset
      puts "storage reset."
    rescue StandardError => e
      puts e.message
    end
    map "x" => "reset"

    desc "snap restore", "snap and restore template"
    options template_name: :string
    def snap_and_restore_template(path)
      snap path
      @captain.clear_file_content
      @captain.restore_template_snapshot(@template_name)
      puts "And restored template '#{@template_name}'."
    rescue StandardError => e
      puts e.message
    end
    map "sart" => "snap_and_restore_template"

    private

    def setup(path)
      @template = options[:template]
      @snapshot_name = options[:name]
      @move_backward = options[:bwd]
      @move_forward = options[:fwd]
      @index = options[:index]
      @clear = options[:clear]
      @template_name = options[:template_name]
      @captain = Captain.new(path)
    end
  end
end
