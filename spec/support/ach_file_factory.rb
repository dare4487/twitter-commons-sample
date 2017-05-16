# Generates ACH files for tests
class ACH::FileFactory
  def self.sample_file(custom_attrs = {})
    attrs = {:company_id => '11-11111', :company_name => 'MY COMPANY'}
    attrs.merge!(custom_attrs)
    with_transmission = attrs.delete(:transmission_header)
    
    klass = ACH::File
    if with_transmission
      klass = Class.new(klass) do
        transmission_header do
          request_type          '$$ADD ID='
          remote_id             '132'
          blank                 ' '
          batch_id_parameter    'BID='
          starting_single_quote "'"
          file_type             'NWFACH'
          application_id        '321'
          ending_single_quote   "'"
        end
      end
    end
    
    klass.new(attrs) do
      immediate_dest '123123123'
      immediate_dest_name 'COMMERCE BANK'
      immediate_origin '123123123'
      immediate_origin_name 'MYCOMPANY'
      
      ['WEB', 'TEL'].each do |code|
        batch(:entry_class_code => code, :company_entry_descr => 'TV-TELCOM') do
          effective_date Time.now.strftime('%y%m%d')
          desc_date      Time.now.strftime('%b %d').upcase
          origin_dfi_id "00000000"
          entry :customer_name  => 'JOHN SMITH',
                :customer_acct  => '61242882282',
                :amount         => '2501',
                :routing_number => '010010101',
                :bank_account   => '103030030'
          addenda :addenda_type_code          => '05',
                  :payment_related_info       => 'foo bar',
                  :addenda_sequence_num       => 1,
                  :entry_details_sequence_num => 1
        end
      end
    end
  end


  def self.with_transmission_header(custom_attrs = {})
    define_transmission_header_fields
    attrs = {:transmission_header => true}.merge(custom_attrs)
    sample_file(attrs)
  end
  
  def self.define_transmission_header_fields
    unless ACH::Formatter.defined?(:request_type)
      ACH::Formatter::RULES.merge!({
        :request_type => '<-9-',
        :remote_id => '<-8-',
        :blank => '<-1-',
        :batch_id_parameter => '<-4-',
        :starting_single_quote => '<-1' ,
        :file_type => '<-6-',
        :application_id => '->8' ,
        :ending_single_quote => '<-1' ,
      })
    end
  end
end
