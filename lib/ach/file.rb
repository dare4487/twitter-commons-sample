module ACH
  # An ACH::File instance represents an actual ACH file. Every file has an
  # ACH::File::Header and ACH::File::Control records and a variable number of
  # ACH::Batches. The ACH::File::TransmissionHeader is optional. (Refer to the
  # target financial institution's documentation.)
  #
  # == Example
  #
  #   # Subclass ACH::File to set default values:
  #   class CustomAchFile < ACH::File
  #     immediate_dest        '123123123'
  #     immediate_dest_name   'COMMERCE BANK'
  #     immediate_origin      '123123123'
  #     immediate_origin_name 'MYCOMPANY'
  #   end
  #
  #   # Create a new instance:
  #   ach_file = CustomAchFile.new do
  #     batch(:entry_class_code => "WEB", :company_entry_descr => "TV-TELCOM") do
  #       effective_date Time.now.strftime('%y%m%d')
  #       desc_date      Time.now.strftime('%b %d').upcase
  #       origin_dfi_id "00000000"
  #       entry :customer_name  => 'JOHN SMITH',
  #             :customer_acct  => '61242882282',
  #             :amount         => '2501',
  #             :routing_number => '010010101',
  #             :bank_account   => '103030030'
  #     end
  #   end
  #   
  #   # convert to string
  #   ach_file.to_s! # => returns string representation of file
  #
  #   # write to file
  #   ach_file.write('custom_ach.txt')
  class File < Component
    autoload :Builder
    autoload :Control
    autoload :Header
    autoload :TransmissionHeader
    autoload :Reader

    include Builder
    include TransmissionHeader

    has_many :batches, :proc_defaults => lambda{ {:batch_number => batches.length + 1} }

    # Open a +filename+ and pass its handler to the ACH::Reader object,
    # which uses it as an enum to scan for ACH contents line by line.
    #
    # @param [String] filename
    # @return [ACH::File]
    def self.read(filename)
      ::File.open(filename) do |fh|
        Reader.new(fh).to_ach
      end
    end
  end
end
