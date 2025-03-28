# frozen_string_literal: true

RSpec.describe "#{Fileverse::Parser::Header} fails" do
  it "should successfully verify header line" do
    allow(File).to receive(:foreach).and_return(["<######0", "######>"].each)
    header = Fileverse::Parser::Header.new("")
    expect { header.parse }.not_to raise_error
  end

  it "should throw error for wrong header line" do
    allow(File).to receive(:foreach).and_return(["#fsd"].each)
    header = Fileverse::Parser::Header.new("")
    expect { header.parse }.to raise_error(Fileverse::CorruptFormat)
  end

  it "should raise for non ascending line numbers" do
    allow(File).to receive(:foreach).and_return(["<######0", "4 ~> 3", "9 ~> 17", "######>"].each)
    header = Fileverse::Parser::Header.new("")
    expect { header.parse }.to raise_error(Fileverse::CorruptFormat)
  end
end

RSpec.describe "#{Fileverse::Parser::Header} pass" do
  it "should parse successfully for header with snapshots" do
    allow(File).to receive(:foreach).and_return([
      "<######0",
      "5 ~> 7",
      "7 ~> 9",
      "9 ~> 12",
      "######>",
      "You're",
      "welcome",
      "to",
      "fileverse.",
      "control",
      "your",
      "files"
    ].each)
    header = Fileverse::Parser::Header.new("")
    expect { header.parse }.not_to raise_error
    expect(header.snapshot_count).to eq(3)
  end
end
