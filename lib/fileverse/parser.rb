# frozen_string_literal: true

module Fileverse
  module Parser
    # Fileverse::Parser::Header : is the main parser for the storage file.
    # Lets take a storage file example:
    #
    # == Storage file Example content
    #
    # <######0
    # template>shot> 6 ~> 9
    # 9 ~> 12
    # 12 ~> 15
    # 15 ~> 18
    # ######>
    # // New file
    # // Write here
    # // When you can
    # File 1
    # Content 1 of file 1
    # Content 2 of file 1
    # File 2
    # Content 1 of file 2
    # Content 2 of file 2
    # File 3
    # Content 1 of file 3
    # Content 2 of file 3
    #
    #
    # == Example end
    #
    # It uses the head section which is what is between "<######{cursor}" and "######>".
    # It starts with "templates" and then "files". Each has a range which is represented like "{start} ~> {stop}".
    # templates are represented as "template>{name}>{range}". While files are just represented as "{range}".
    # so the above example will parse as follows:
    #
    # - template>shot> 6 ~> 9
    #
    # =======================================
    # |   // New file
    # |   // Write here
    # |   // When you can
    # ======================================
    #
    # - 9 ~> 12
    #
    # =======================================
    # |   File 1
    # |   Content 1 of file 1
    # |   Content 2 of file 1
    # ======================================
    #
    # - 12 ~> 15
    #
    # =======================================
    # |   File 2
    # |   Content 1 of file 2
    # |   Content 2 of file 2
    # ======================================
    #
    # - 15 ~> 18
    #
    # =======================================
    # |   File 3
    # |   Content 1 of file 3
    # |   Content 2 of file 3
    # ======================================
    #
    class Header # rubocop:disable Metrics/ClassLength
      START_TAG = "<######"
      CLOSE_TAG = "######>"

      attr_reader :path, :cursor, :line_index

      def initialize(path)
        @path = path
        @iterator = File.foreach(path, chomp: true)
        @line_index = 0
        @cursor = -1
        @snapshots = []
        @templates = []
      end

      def parse
        return if @iterator.size.zero? # rubocop:disable Style/ZeroLengthPredicate

        verify_first_header
        parse_header_template_lines
        parse_header_snapshot_lines
        parse_snapshots

        raise CorruptFormat, " Content remains after parsing." unless peek_line.nil?
      end

      def snapshot_count
        @snapshots.length
      end

      def add_snapshot(content)
        last_snapshot = @snapshots[-1]
        start = last_snapshot&.stop || 3
        snapshot = Snapshot.new(start, start + content.length)
        snapshot.content = content
        last_snapshot&.next_snapshot = snapshot
        @snapshots.push(snapshot)
        reset_cursor
      end

      def cursor_content
        @snapshots[@cursor]&.content
      end

      def remove_cursor_snapshot
        snapshot = @snapshots[@cursor]
        return unless snapshot

        snapshot_before = @snapshots[@cursor - 1]
        snapshot_before.next_snapshot = snapshot.next_snapshot if snapshot_before
        @snapshots = @snapshots[0, @cursor].concat(@snapshots[@cursor + 1..])
      end

      def to_writable_lines
        [*head_lines, *template_lines, *snapshot_lines]
      end

      private

      def reset_cursor
        @cursor = @snapshots.length - 1
      end

      def verify_first_header
        first_line = next_line
        /\A<\#{6}(?<cursor>\d+)\z/ =~ first_line
        raise CorruptFormat unless cursor

        @cursor = cursor.to_i
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
          *@templates.map { |template| "template>#{template.name}> #{template.start} ~> #{template.stop}" },
          *@snapshots.map { |snap| "#{snap.start} ~> #{snap.stop}" },
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
