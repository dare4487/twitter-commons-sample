require 'spec_helper'

describe ACH::File do

  context "building the ACH file" do
    before(:each) do
      @attributes = {
        :company_id => '11-11111',
        :company_name => 'MY COMPANY',
        :immediate_dest => '123123123',
        :immediate_dest_name => 'COMMERCE BANK',
        :immediate_origin => '123123123',
        :immediate_origin_name => 'MYCOMPANY' }
      @invalid_attributes = {:foo => 'bar'}
      @file = ACH::File.new(@attributes)
      @file_with_batch = ACH::File.new(@attributes) do
        batch :entry_class_code => 'WEB'
      end
      @sample_file = ACH::FileFactory.sample_file
    end

    it "should correctly assign attributes" do
      @file.company_id.should == '11-11111'
    end

    it "should be modified by calling attribute methods in block" do
      file = ACH::File.new(@attributes) do
        company_name "MINE COMPANY"
      end
      file.company_name.should == "MINE COMPANY"
    end

    it "should fetch and return header" do
      head = @file.header
      head.should be_instance_of(ACH::File::Header)
      head.immediate_dest.should == '123123123'
    end

    it "should be able to modify header info in block form" do
      file = ACH::File.new(@attributes) do
        header(:immediate_dest => '321321321') do
          immediate_dest_name 'BANK COMMERCE'
        end
      end
      head = file.header
      head.immediate_dest.should == '321321321'
      head.immediate_dest_name.should == 'BANK COMMERCE'
    end

    it "should raise exception on unknown attribute assignement" do
      lambda {
        ACH::File.new(@invalid_attributes)
      }.should raise_error(ACH::Component::UnknownAttributeError)
    end

    it "should be able to create a batch" do
      @file_with_batch.batches.should_not be_empty
    end

    it "should return a batch when index is passed" do
      @file_with_batch.batches[0].should be_instance_of(ACH::Batch)
    end

    it "should assign a batch_number to a batch" do
      batch = @file_with_batch.batches[0]
      batch.batch_number.should == 1
      batch = @file_with_batch.batch(:entry_class_code => 'WEB')
      batch.batch_number.should == 2
    end

    it "should assign attributes to a batch" do
      batch = @file_with_batch.batches[0]
      batch.attributes.should include(@file_with_batch.attributes)
    end

    it "should have correct record count" do
      @sample_file.record_count.should == 10
    end

    it "should have header and control record with length of 94" do
      [:header, :control].each do |record|
        @sample_file.send(record).to_s!.length.should == ACH::Constants::RECORD_SIZE
      end
    end

    it "should have length devisible by 94 (record size)" do
      (@sample_file.to_s!.gsub(ACH::Constants::ROWS_DELIMITER, '').length % ACH::Constants::RECORD_SIZE).should be_zero
    end


    describe 'transmission header' do
      before(:all) do
        @with_transmission_header
        attrs = {:remote_id => 'ZYXWVUTS', :application_id => '98765432'}
        ach_file = ACH::FileFactory.with_transmission_header(attrs)
        @transmission_header = ach_file.to_s!.split(ACH::Constants::ROWS_DELIMITER).first
      end

      it "should raise error when defining empty transmission header" do
        expect do
          Class.new(ACH::File) do
            transmission_header
          end
        end.to raise_error(ACH::File::EmptyTransmissionHeaderError)
      end

      it "have_transmission_header? method should return proper value" do
        without_header = Class.new(ACH::File)
        with_header = Class.new(ACH::File) do
          transmission_header do
            application_id
          end
        end

        without_header.have_transmission_header?.should be_false
        with_header.have_transmission_header?.should be_true
      end

      it "has length of 38" do
        @transmission_header.length.should == 38
      end

      it "has specified remote_id" do
        @transmission_header[9..16].should == 'ZYXWVUTS'
      end

      it "has specified application_id" do
        @transmission_header[29..36].should == '98765432'
      end
    end

    it 'number of records is multiple of 10 (transmission header is ignored)' do
      records = ACH::FileFactory.sample_file.to_s!.split(ACH::Constants::ROWS_DELIMITER)
      (records.size % 10).should == 0

      records = ACH::FileFactory.with_transmission_header.to_s!.split(ACH::Constants::ROWS_DELIMITER)
      ((records.size - 1) % 10).should == 0
    end

    describe 'inherited class' do
      before(:all) do
        @custom_file_class = Class.new(ACH::File) do
          immediate_dest_name 'CUSTOM VALUE'
          customer_name "PETER PARKER"
        end

        @custom_file = @custom_file_class.new do
          immediate_dest '123123123'
          immediate_origin '123123123'
          immediate_origin_name 'MYCOMPANY'
          batch(:entry_class_code => "WEB", :company_entry_descr => 'TV-TELCOM') do
            effective_date Time.now.strftime('%y%m%d')
            desc_date      Time.now.strftime('%b %d').upcase
            origin_dfi_id "00000000"
            entry :customer_acct     => '61242882282',
                  :amount            => '2501',
                  :routing_number    => '010010101',
                  :bank_account      => '103030030'
          end
        end
      end

      it 'should use default values defined in inherited class' do
        header = @custom_file.header
        header.immediate_dest_name.should == "CUSTOM VALUE"
        entry = @custom_file.batches.first.entries.first
        entry.customer_name.should == "PETER PARKER"
      end
    end

    describe "file control" do
      subject { @file.control }
      it { should be_an ACH::File::Control }
    end
  end

  context "reading the ACH file" do
    before(:each) { @result = ACH::File.read well_fargo_empty_filename }
    subject { @result }
    it { should be_an ACH::File }
  end
end
