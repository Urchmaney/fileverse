# frozen_string_literal: true

RSpec.describe "#{Fileverse::Parser::Header} fails" do
  it "should successfully verify header line" do
    allow(File).to receive(:foreach).and_return(["<######0", "######>"].each)
    header = Fileverse::Parser::Header.new("")
    expect { header.parse }.not_to raise_error
  end

  it "should throw error for wrong header line" do
    allow(File).to receive(:foreach).and_return(["#fsd"].each)
    allow(File).to receive(:exist?).and_return(true)
    header = Fileverse::Parser::Header.new("")
    expect { header.parse }.to raise_error(Fileverse::CorruptFormat)
  end

  it "should raise for non ascending line numbers" do
    allow(File).to receive(:foreach).and_return(["<######0", "4 ~> 3", "9 ~> 17", "######>"].each)
    allow(File).to receive(:exist?).and_return(true)
    header = Fileverse::Parser::Header.new("")
    expect { header.parse }.to raise_error(Fileverse::CorruptFormat)
  end
end

RSpec.describe "#{Fileverse::Parser::Header} pass" do
  correct_format = [
    "<######0", "5 ~> 7", "7 ~> 9", "9 ~> 12", "######>",
    "You're", "welcome", "to", "fileverse.", "control", "your", "files"
  ]
  it "should parse successfully for header with snapshots" do
    allow(File).to receive(:foreach).and_return(correct_format.each)
    allow(File).to receive(:exist?).and_return(true)
    header = Fileverse::Parser::Header.new("")
    expect { header.parse }.not_to raise_error
    expect(header.snapshot_count).to eq(3)
  end

  it "should return same array for writable" do
    allow(File).to receive(:foreach).and_return(correct_format.each)
    allow(File).to receive(:exist?).and_return(true)
    header = Fileverse::Parser::Header.new("")
    header.parse
    expect(header.to_writable_lines).to eq(correct_format)
  end
end

RSpec.describe "#{Fileverse::Parser::Header} with template pass" do
  correct_format = [
    "<######0", "template>jude> 6 ~> 8", "8 ~> 10", "10 ~> 12", "12 ~> 15", "######>", "import love from 'fileverse'",
    "", "You're", "welcome", "to", "fileverse.", "control", "your", "files"
  ]
  it "should parse successfully for header with template and snapshots" do
    allow(File).to receive(:foreach).and_return(correct_format.each)
    allow(File).to receive(:exist?).and_return(true)
    header = Fileverse::Parser::Header.new("")
    expect { header.parse }.not_to raise_error
    expect(header.snapshot_count).to eq(3)
    expect(header.to_writable_lines).to eq(correct_format)
  end
end

RSpec.describe "#{Fileverse::Parser::Header} add snapshot" do
  snapshot = %w[new snapshot]
  correct_format = [
    "<######0", "3 ~> 5", "######>", *snapshot
  ]
  it "should parse successfully for header with template and snapshots" do
    header = Fileverse::Parser::Header.new("")
    header.add_snapshot(snapshot)
    expect(header.to_writable_lines).to eq(correct_format)
  end
end
