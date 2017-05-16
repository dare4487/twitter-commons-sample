require 'spec_helper'

describe ACH::Component::HasManyAssociation do
  before(:all) do
    ACH::Element = Class.new(ACH::Component)
    ACH::Record::Item = Class.new(ACH::Record::Dynamic) do
      item_id '<-3' => 'foo'
    end
  end

  after(:all) do
    ACH.remove_const(:Element)
    ACH::Record.remove_const(:Item)
  end

  describe "properties" do
    before(:each) do
      @association = ACH::Component::HasManyAssociation.new(:elements)
    end

    it "should have proper klass" do
      @association.send(:klass).should == ACH::Element
    end

    it "should have proper singular name" do
      @association.send(:singular_name).should == 'element'
    end

    it "should have proper set of delegation methods" do
      @association.delegation_methods.to_set.should == %w{elements element build_element}.to_set
    end

    describe "owner assignment" do
      before(:each) do
        @assigned = @association.for(ACH::Element.new)
      end

      it "should have @owner assigned" do
        @assigned.instance_variable_get('@owner').should_not be_nil
      end

      it "should not share containers" do
        @other = @association.for(ACH::Element.new)
        @assigned.container.object_id.should_not == @other.container.object_id
      end

      it "should have method aliases for owner to delegate" do
        @association.delegation_methods.each do |method_name|
          @assigned.should respond_to method_name
        end
      end
    end

    describe "reassignment" do
      it "should raise error" do
        assigned = @association.for(Object.new)
        expect{ assigned.for(Object.new) }.to raise_error(ACH::Component::HasManyAssociation::DoubleAssignmentError)
      end
    end

    describe "without :linked_to option" do
      it "should have Array as container" do
        @association.container.should be_an Array
      end

      it "container_for_associated should be the same as container" do
        @association.container_for_associated.object_id.should == @association.container.object_id
      end
    end

    describe "with :linked_to option" do
      before(:each) do
        @linked_association = ACH::Component::HasManyAssociation.new(:items, :linked_to => :elements)
        @assigned = @association.for(ACH::Element.new)
        @linked_assigned = @linked_association.for(@assigned)
      end

      it "should have proper klass" do
        @linked_association.send(:klass).should == ACH::Record::Item
      end

      it "should have Hash as container" do
        @linked_association.container.should be_a Hash
      end

      it "container_for_associated should raise NoLinkError if there is no parent record created" do
        expect {
          @linked_assigned.container_for_associated
        }.to raise_error(ACH::Component::HasManyAssociation::NoLinkError)
      end

      it "container_for_associated should be array if there is parent record" do
        @assigned.create
        @linked_assigned.container_for_associated.should be_an Array
      end
    end

    describe "with :proc_defaults option" do
      before(:each) do
        @proc_association = ACH::Component::HasManyAssociation.new(
          :items, :proc_defaults => lambda{ {:item_id => 'bar'} }
        ).for(ACH::Element.new)
      end

      it "created item should have proper value" do
        item = @proc_association.create
        item.item_id.should == 'bar'
      end
    end
  end
end