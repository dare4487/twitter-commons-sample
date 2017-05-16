require 'spec_helper'

describe ACH::Record::Addenda do
  it "should have length of 94" do
    addenda = ACH::FileFactory.sample_file.batches[0].addendas.values.flatten.first
    addenda.to_s!.size.should == 94
  end
end
