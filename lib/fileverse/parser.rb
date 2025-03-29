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
      end

      def parse
        verify_first_header
        parse_header_lines
        parse_snapshots
      end

      def snapshot_count
        @snapshots.length
      end

      def to_writable_lines
        [*head_lines, *snapshot_lines]
      end

      private

      def verify_first_header
        first_line = next_line
        /\A<\#{6}(?<cursor>\d+)\z/ =~ first_line
        raise CorruptFormat unless cursor

        @cursor = cursor
      end

      def parse_header_lines
        loop do
          line = next_line
          unless /\A[[:blank:]]*(?<start>\d+)[[:blank:]]*~>[[:blank:]]*(?<stop>\d+)[[:blank:]]*\z/ =~ line
            break if line == CLOSE_TAG

            raise CorruptFormat
          end
          raise CorruptFormat if stop.to_i < start.to_i

          @snapshots.push Snapshot.new(start.to_i, stop.to_i)
        end
      end

      def parse_snapshots
        last_snap = nil
        @snapshots.each do |snap|
          raise CorruptFormat, " Wrong indexing in header." if line_index != snap.start

          snap.content = parse_snap_content(snap)
          last_snap&.next_snapshot = snap
          last_snap = snap
        end

        raise CorruptFormat, " Content remains after parsing." unless peek_line.nil?
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

      def snapshot_lines
        @snapshots.map(&:content).flatten
      end

      # Snapshot for each file
      class Snapshot
        attr_reader :start, :stop, :content
        attr_accessor :next_snapshot

        def initialize(start, stop)
          @start = start
          @stop = stop
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
