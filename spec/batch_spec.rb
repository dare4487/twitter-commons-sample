require 'spec_helper'

describe ACH::Batch do
  before(:each) do
    @batch = ACH::Batch.new
    @file = ACH::FileFactory.sample_file
  end
  
  it "should create entry with attributes in hash form" do
    entry = @batch.entry :amount => 100
    entry.should be_instance_of(ACH::Record::Entry)
    entry.amount.should == 100
  end
  
  it "should create entry with attributes in block form" do
    entry = @batch.entry do
      amount 100
    end
    entry.amount.should == 100
  end
  
  it "should raise error when adding addenda records without any entry" do
    batch = ACH::Batch.new
    expect{ batch.addenda(:payment_related_info =>'foo bar') }.to raise_error(ACH::Component::HasManyAssociation::NoLinkError)
  end
  
  it "should append addenda records after entry records" do
    batch = ACH::Batch.new
    3.times do |i|
      batch.entry(:amount => 100)
      i.times{ batch.addenda(:payment_related_info => 'foo bar') }
    end
    batch.to_ach.map(&:class)[1...-1].should == [ACH::Record::Entry, ACH::Record::Entry, ACH::Record::Addenda, ACH::Record::Entry, ACH::Record::Addenda, ACH::Record::Addenda]
  end
  
  it "should return false for has_credit? and has_debit? for empty entries" do
    @batch.has_credit?.should be_false
    @batch.has_debit?.should be_false
  end
  
  it "should return true for has_credit? if contains credit entry" do
    @batch.entry :amount => 100, :transaction_code => 21
    @batch.has_credit?.should be_true
  end
  
  it "should return true for has_debit? if contains debit entry" do
    @batch.entry :amount => 100
    @batch.has_debit?.should be_true
  end
  
  it "should generate 225 service_class_code for header if with debit entry only" do
    @batch.entry :amount => 100
    @batch.header.service_class_code.should == 225
  end
  
  it "should generate 220 service_class_code for header if with credit entry only" do
    @batch.entry :amount => 100, :transaction_code => 21
    @batch.header.service_class_code.should == 220
  end
  
  it "should generate 200 service_class_code for header if with debit and credit entries" do
    @batch.entry :amount => 100
    @batch.entry :amount => 100, :transaction_code => 21
    @batch.header.service_class_code.should == 200
  end
  
  it "should have header and control record with length of 94" do
    [:header, :control].each do |record|
      @file.batches[0].send(record).to_s!.length.should == ACH::Constants::RECORD_SIZE
    end
  end

end
