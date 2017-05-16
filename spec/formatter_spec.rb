require 'spec_helper'

describe ACH::Formatter do
  before(:all) do
    module ACH::Formatter
      # redefining RULES FOR new test values
      RULES = remove_const(:RULES).dup
      RULES[:ljust_5] = '<-5'
      RULES[:ljust_5_transform] = '<-5|upcase'
      RULES[:rjust_6] = '->6'
      RULES[:rjust_6_spaced] = '->6-'
    end
  end
  
  it{ ACH::Formatter.ljust_5('foo').should == 'foo  ' }
  
  it{ ACH::Formatter.ljust_5_transform('bar').should == 'BAR  ' }
  
  it{ ACH::Formatter.rjust_6(1599).should == '001599' }
  
  it{ ACH::Formatter.rjust_6_spaced(1599).should == '  1599' }
end
