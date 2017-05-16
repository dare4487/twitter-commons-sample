require 'spec_helper'

describe ACH::Record::Dynamic do
  before(:all) do
    @valid_record_definition = lambda do
      Class.new(ACH::Record::Dynamic) do
        record_name
        record_id '345'
        field_one '->1'
        field_two '->2', 34
        field_three '->3' => 45
      end
    end
  end
  
  before(:each) do
    module ACH::Formatter
      # redefining RULES FOR new test values
      remove_const(:OLD_RULES) if defined? OLD_RULES
      OLD_RULES = remove_const(:RULES)
      RULES = {
        :record_id => '->5',
        :record_name => '<-10' }
    end
  end
  
  after(:each) do
    module ACH::Formatter
      remove_const(:RULES)
      RULES = OLD_RULES
    end
  end
  
  it "should should not raise error on valid record definition" do
    expect(&@valid_record_definition).to_not raise_error
  end
  
  it "should add new rules to a formatter" do
    @valid_record_definition.call
    ACH::Formatter::RULES.keys.should include(:field_one, :field_two, :field_three)
  end
  
  it "should add declared fields to a record" do
    klass = @valid_record_definition.call
    klass.fields.should == [:record_name, :record_id, :field_one, :field_two, :field_three]
  end
  
  it "should assign default values to a record" do
    klass = @valid_record_definition.call
    expected_defaults = {
      :record_id => '345',
      :field_two => 34,
      :field_three => 45 }
    klass.defaults.should == expected_defaults
  end
  
  it "should raise error when redefining new rule" do
    [['->5'], ['->5', '123'], [{'->5' => '123'}]].each do |args|
      expect do
        Class.new(ACH::Record::Dynamic) do
          record_name *args
        end
      end.to raise_error(ACH::Record::Dynamic::DuplicateFormatError)
    end
  end
  
  it "should raise error when declaring unknown field without specifying a format" do
    expect do
      Class.new(ACH::Record::Dynamic) do
        field_four
      end
    end.to raise_error(ACH::Record::Dynamic::UndefinedFormatError)
  end
end
