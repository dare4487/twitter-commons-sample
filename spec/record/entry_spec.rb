require 'spec_helper'

describe ACH::Record::Entry do
  it "should have length of 94" do
    ACH::FileFactory.sample_file.batches[0].entries[0].to_s!.length.should == ACH::Constants::RECORD_SIZE
  end
end
