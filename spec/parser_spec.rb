# frozen_string_literal: true

RSpec.describe "#{Fileverse::Parser} fails" do
  it "should successfully verify header line" do
    allow(File).to receive(:foreach).and_return(["<######0", "######>"].each)
    parser = Fileverse::Parser.new("")
    expect { parser.parse }.not_to raise_error
  end

  it "should throw error for wrong header line" do
    allow(File).to receive(:foreach).and_return(["#fsd"].each)
    allow(File).to receive(:exist?).and_return(true)
    parser = Fileverse::Parser.new("")
    expect { parser.parse }.to raise_error(Fileverse::CorruptFormat)
  end

  it "should raise for non ascending line numbers" do
    allow(File).to receive(:foreach).and_return(["<######0", "4 ~> 3", "9 ~> 17", "######>"].each)
    allow(File).to receive(:exist?).and_return(true)
    parser = Fileverse::Parser.new("")
    expect { parser.parse }.to raise_error(Fileverse::CorruptFormat)
  end
end

RSpec.describe "#{Fileverse::Parser} pass" do
  correct_format = [
    "<######0", "5 ~> 7", "7 ~> 9", "9 ~> 12", "######>",
    "You're", "welcome", "to", "fileverse.", "control", "your", "files"
  ]
  it "should parse successfully for header with snapshots" do
    allow(File).to receive(:foreach).and_return(correct_format.each)
    allow(File).to receive(:exist?).and_return(true)
    parser = Fileverse::Parser.new("")
    expect { parser.parse }.not_to raise_error
    expect(parser.snapshot_count).to eq(3)
  end

  it "should return same array for writable" do
    allow(File).to receive(:foreach).and_return(correct_format.each)
    allow(File).to receive(:exist?).and_return(true)
    parser = Fileverse::Parser.new("")
    parser.parse
    expect(parser.to_writable_lines).to eq(correct_format)
  end
end

RSpec.describe "#{Fileverse::Parser} with names snapshots" do # rubocop:disable Metrics/BlockLength
  correct_format = [
    "<######0", "jude>6 ~> 8", "8 ~> 10", "10 ~> 12", "12 ~> 15", "######>", "import love from 'fileverse'",
    "", "You're", "welcome", "to", "fileverse.", "control", "your", "files"
  ]

  it "should parse successfully for header with named snapshots" do
    allow(File).to receive(:foreach).and_return(correct_format.each)
    allow(File).to receive(:exist?).and_return(true)
    parser = Fileverse::Parser.new("")
    expect { parser.parse }.not_to raise_error
    expect(parser.snapshot_count).to eq(4)
    expect(parser.to_writable_lines).to eq(correct_format)
  end

  it "should successfully add named snapshots" do
    snapshot = %w[new snapshot]
    add_correct_format = [
      "<######0", "sloan>3 ~> 5", "######>", *snapshot
    ]
    parser = Fileverse::Parser.new("")
    parser.add_snapshot(snapshot, "sloan")
    expect(parser.to_writable_lines).to eq(add_correct_format)
  end

  it "should find snapshot with name or otherwise nil" do
    allow(File).to receive(:foreach).and_return(correct_format.each)
    allow(File).to receive(:exist?).and_return(true)
    parser = Fileverse::Parser.new("")
    parser.parse
    result = parser.snapshot_content_by_name("jude")
    expect(result.length).to be(2)
    expect { parser.snapshot_content_by_name("jule") }.to raise_error(Fileverse::NoContentForName)
  end
end
