require 'spec_helper'

describe ACH::File::Reader do
  context "reading from file" do
    { 'empty' => well_fargo_empty_filename, 'non-empty' => well_fargo_with_data }.each do |description, file|
      context description do
        before do
          @source   = file
          @ach_file = ACH::File::Reader.new(File.readlines(@source)).to_ach
        end

        subject { @ach_file }

        it "should return instance of the ACH::File" do
          should be_instance_of ACH::File
        end

        describe "reverse conversion" do
          before do
            @result = @ach_file.to_s!
            @result.gsub! /^9+\n?$/, ''
            @result.gsub! /^\n$/,    ''
          end

          subject { @result }
          it { should be_a String }
          it "should be eql to source string" do
            should == File.read(@source)
          end
        end
      end
    end
  end

  context "reading ACH file without batches" do
    before do
      @source   = well_fargo_empty_filename
      @ach_file = ACH::File::Reader.new(File.readlines(@source)).to_ach
    end

    it { @ach_file.header.should be_an ACH::File::Header }
    it { @ach_file.batches.count.should == 0 }
  end

  context "reading ACH file with batch" do
    before do
      @source   = well_fargo_with_data
      @ach_file = ACH::File::Reader.new(File.readlines(@source)).to_ach
    end

    it { @ach_file.header.should be_an ACH::File::Header }
    it { @ach_file.batches.count.should == 1 }
  end

end