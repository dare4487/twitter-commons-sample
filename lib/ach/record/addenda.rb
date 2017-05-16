module ACH
  module Record
    # An ACH::Record::Addenda is an ACH::Record::Base record located inside of
    # an ACH::Batch component. An addenda record should be preceded by an
    # ACH::Record::Entry record.
    #
    # == Fields
    #
    # * record_type
    # * addenda_type_code
    # * payment_related_info
    # * addenda_sequence_num
    # * entry_details_sequence_num
    class Addenda < Base
      fields :record_type,
        :addenda_type_code,
        :payment_related_info,
        :addenda_sequence_num,
        :entry_details_sequence_num

      defaults :record_type => BATCH_ADDENDA_RECORD_TYPE,
        :addenda_type_code => 5
    end
  end
end
