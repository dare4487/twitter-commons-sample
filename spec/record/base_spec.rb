require 'spec_helper'

describe ACH::Record::Base do
  before(:all) do
    @test_record = Class.new(ACH::Record::Base) do
      fields :customer_name, :amount
      defaults :customer_name => 'JOHN SMITH'
    end
  end
  
  it "should have 2 ordered fields" do
    @test_record.fields.should == [:customer_name, :amount]
  end
  
  it "should create a record with default value" do
    @test_record.new.customer_name.should == 'JOHN SMITH'
  end
  
  it "should overwrite default value" do
    entry = @test_record.new(:customer_name => 'SMITH JOHN')
    entry.customer_name.should == 'SMITH JOHN'
  end
  
  it "should generate formatted string" do
    entry = @test_record.new :amount => 1599
    entry.to_s!.should == "JOHN SMITH".ljust(22) + "1599".rjust(10, '0')
  end
  
  it "should raise exception with unfilled value" do
    lambda{
      @test_record.new.to_s!
    }.should raise_error(ACH::Record::Base::EmptyFieldError)
  end

  context "creating record from string" do
    before :each do
      @content = "JOHN SMITH            0000000005"
      @record  = @test_record.from_s @content
    end

    it "should be an instance of ACH::Record" do
      @record.is_a?(ACH::Record::Base).should be_true
    end

    it "should has correctly detected amount" do
      @record.fields[:amount].should == '0000000005'
    end

    it "should has correctly detected customer_name" do
      @record.fields[:customer_name].should == 'JOHN SMITH            '
    end
  end
end
