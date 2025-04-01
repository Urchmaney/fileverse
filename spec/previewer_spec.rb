# frozen_string_literal: true

RSpec.describe Fileverse::Previewer do
  it "should parse main content if no snapshot" do
    allow(File).to receive(:read).and_return("show \n the file \n to test")
    previewer = Fileverse::Previewer.new("")
    previewer.parse
    expect(previewer.to_writable_lines).to eq(["show ", " the file ", " to test"])
  end

  it "should parse with new snapshot" do
    allow(File).to receive(:read).and_return("#{Fileverse::Previewer::PREVIEW_HEAD}\n
    first snapshot\n#{Fileverse::Previewer::PREVIEW_FOOTER}show \n the file \n to test")
    previewer = Fileverse::Previewer.new("")
    previewer.parse
    new_content = ["second snapshot"]
    previewer.preview_content = new_content
    expect(previewer.to_writable_lines).to eq([
                                                Fileverse::Previewer::PREVIEW_HEAD,
                                                *new_content,
                                                Fileverse::Previewer::PREVIEW_FOOTER,
                                                "show ",
                                                " the file ", " to test"
                                              ])
  end
end
