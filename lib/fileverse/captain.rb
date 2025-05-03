# frozen_string_literal: true

module Fileverse
  #
  # The main ordinator for the clis
  #
  class Captain
    def initialize(file_path)
      @file_path = Files.expand_path(file_path)
    end

    def snap_content_to_file_storage(snapshot_name)
      content = Files.read(@file_path)
      file_storage_parser.add_snapshot(content, snapshot_name)
    end

    def snap_content_to_template_storage(snapshot_name)
      content = Files.read(@file_path)
      template_storage_parser.add_snapshot(content, snapshot_name)
    end

    def clear_file_content
      Files.clear_content(@file_path)
    end

    def save_template_storage
      Files.write_content(Files.template_storage_path, template_storage_parser.to_writable_lines)
    end

    def save_file_storage
      Files.write_content(file_storage_path, file_storage_parser.to_writable_lines)
    end

    def restore_file_snapshot(remove_snapshot: false)
      Files.write_content(@file_path, file_storage_parser.cursor_content)
      file_storage_parser.remove_cursor_snapshot if remove_snapshot
      save_file_storage
    end

    def restore_template_snapshot(snapshot_name)
      Files.write_content(@file_path, template_storage_parser.snapshot_content_by_name(snapshot_name))
    end

    def preview_backward(is_template: false)
      previewer.preview_content = (
        is_template ? template_storage_parser : file_storage_parser).snapshot_content_backward
      save_preview(is_template: is_template)
    end

    def preview_forward(is_template: false)
      previewer.preview_content = (
        is_template ? template_storage_parser : file_storage_parser).snapshot_content_forward
      save_preview(is_template: is_template)
    end

    def preview_current_snapshot(is_template: false)
      previewer.preview_content = (
        is_template ? template_storage_parser : file_storage_parser).cursor_content
      save_preview(is_template: is_template)
    end

    def preview_by_snap_name(name, is_template: false)
      previewer.preview_content = (
        is_template ? template_storage_parser : file_storage_parser).snapshot_content_by_name(name)
      save_preview(is_template: is_template)
    end

    def preview_by_snap_index(index, is_template: false)
      previewer.preview_content = (
        is_template ? template_storage_parser : file_storage_parser).snapshot_content_by_index(index)
      save_preview(is_template: is_template)
    end

    def reset
      file_storage_parser.reset
      previewer.preview_content = []
      save_preview(is_template: false)
      save_file_storage
    end

    private

    def save_preview(is_template: false)
      Files.write_content(@file_path, previewer.to_writable_lines)
      is_template ? save_template_storage : save_file_storage
    end

    def file_storage_path
      Files.expand_storage_path(@file_path)
    end

    def file_storage_parser
      @file_storage_parser ||= Parser.new(file_storage_path).tap(&:parse)
    end

    def template_storage_parser
      @template_storage_parser ||= Parser.new(Files.template_storage_path).tap(&:parse)
    end

    def previewer
      @previewer ||= Previewer.new(@file_path).tap(&:parse)
    end
  end
end
