# frozen_string_literal: true

RSpec.describe Fileverse::Parser do
  describe Fileverse::Parser::Header do
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

    it "should parse correctly" do
      allow(File).to receive(:foreach).and_return(["<######0", "4 ~> 10", "11 ~> 17", "######>"].each)
      header = Fileverse::Parser::Header.new("")
      expect { header.parse }.not_to raise_error
      expect(header.snapshot_count).to eq(2)
    end

    it "should raise for non ascending line numbers" do
      allow(File).to receive(:foreach).and_return(["<######0", "4 ~> 3", "9 ~> 17", "######>"].each)
      header = Fileverse::Parser::Header.new("")
      expect { header.parse }.to raise_error(Fileverse::CorruptFormat)
    end
  end
end
