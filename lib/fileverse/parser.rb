# frozen_string_literal: true

module Fileverse
  module Parser
    # Header class to process header section
    class Header
      START_TAG = "<######"
      CLOSE_TAG = "######>"

      attr_reader :path, :cursor, :line_index

      def initialize(path)
        @path = path
        @iterator = File.foreach(path, chomp: true)
        @line_index = 0
        @cursor = 0
        @snapshots = []
        @templates = []
      end

      def parse
        verify_first_header
        parse_header_template_lines
        parse_header_snapshot_lines
        parse_snapshots

        raise CorruptFormat, " Content remains after parsing." unless peek_line.nil?
      end

      def snapshot_count
        @snapshots.length
      end

      def to_writable_lines
        [*head_lines, *template_lines, *snapshot_lines]
      end

      private

      def verify_first_header
        first_line = next_line
        /\A<\#{6}(?<cursor>\d+)\z/ =~ first_line
        raise CorruptFormat unless cursor

        @cursor = cursor
      end

      def parse_header_template_lines
        loop do
          break unless /\A\s*template>(?<name>\w+)>\s*(?<start>\d+)\s*~>\s*(?<stop>\d+)\s*\z/ =~ peek_line

          next_line
          @templates.push(Snapshot.new(start.to_i, stop.to_i, name))
        end
      end

      def parse_header_snapshot_lines
        loop do
          line = next_line
          unless /\A\s*(?<start>\d+)\s*~>\s*(?<stop>\d+)\s*\z/ =~ line
            break if line == CLOSE_TAG

            raise CorruptFormat
          end
          raise CorruptFormat if stop.to_i < start.to_i

          @snapshots.push Snapshot.new(start.to_i, stop.to_i)
        end
      end

      def parse_snapshots
        last_snap = nil
        [*@templates, *@snapshots].each do |snap|
          raise CorruptFormat, " Wrong indexing in header." if line_index != snap.start

          snap.content = parse_snap_content(snap)

          last_snap&.next_snapshot = snap
          last_snap = snap
        end
      end

      def parse_snap_content(snap)
        result = []
        (snap.stop - snap.start).times { result.push next_line }
        result
      end

      def next_line
        @line_index += 1
        @iterator.next
      rescue StopIteration
        raise CorruptFormat, " No content to parse."
      end

      def peek_line
        @iterator.peek
      rescue StopIteration
        nil
      end

      def head_lines
        [
          "#{START_TAG}#{cursor}",
          *@snapshots.map do |snap|
            "#{snap.start} ~> #{snap.stop}"
          end,
          CLOSE_TAG
        ]
      end

      def template_lines
        @templates.map(&:content).flatten
      end

      def snapshot_lines
        @snapshots.map(&:content).flatten
      end

      # Snapshot for each file
      class Snapshot
        attr_reader :start, :stop, :name, :content
        attr_accessor :next_snapshot

        def initialize(start, stop, name = nil)
          @start = start
          @stop = stop
          @name = name
        end

        def content=(value)
          @content = value
          update_stop
        end

        def update_start(new_start)
          @start = new_start
          update_stop
        end

        private

        def update_stop
          @stop = start + content.length
          next_snapshot&.update_start @stop
        end
      end
    end
  end
end
