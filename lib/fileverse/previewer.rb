# frozen_string_literal: true

require "English"

module Fileverse
  # Previewer parses the main file to check if there is preview content
  # and parse it if there is.
  class Previewer
    PREVIEW_HEAD = "=============SNAPSHOT============"
    PREVIEW_FOOTER = "=================================="

    attr_accessor :preview_content

    def initialize(path)
      @path = path
      @main_content = []
      @preview_content = []
    end

    def parse
      content = File.read @path
      # match = /#{TEMPLATE_HEAD}?(.*)#{TEMPLATE_FOOTER}?(.*)/ =~ conent
      match = /(#{PREVIEW_HEAD})?(?(1)(.*)(#{PREVIEW_FOOTER})(.*)|(.*))/m =~ content
      raise CorruptFormat, " Error: Parsing preview content" if match.nil?

      @preview_content = $LAST_MATCH_INFO[2]&.split("\n") || []
      @main_content = ($LAST_MATCH_INFO[5] || $LAST_MATCH_INFO[4]).split("\n") || []
    end

    def to_writable_lines
      [*writable_preview_section, *@main_content]
    end

    private

    def writable_preview_section
      return @preview_content if @preview_content.empty?

      [PREVIEW_HEAD, *@preview_content, PREVIEW_FOOTER]
    end
  end
end
