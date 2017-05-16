require 'spec_helper'

describe ACH::Record::Tail do
  it "should have length of 94" do
    ACH::Record::Tail.new.to_s!.length.should == ACH::Constants::RECORD_SIZE
  end
end
