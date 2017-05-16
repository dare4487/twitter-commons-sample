module ACH
  # Every ACH::File ends with an ACH::File::Control record.
  #
  # == Fields:
  #
  # * record_type
  # * batch_count
  # * block_count
  # * file_entry_addenda_count
  # * entry_hash
  # * total_debit_amount
  # * total_credit_amount
  # * bank_39
  class File::Control < Record::Base
    fields :record_type,
      :batch_count,
      :block_count,
      :file_entry_addenda_count,
      :entry_hash,
      :total_debit_amount,
      :total_credit_amount,
      :bank_39
    
    defaults :record_type => FILE_CONTROL_RECORD_TYPE,
      :bank_39            => ''
  end
end
