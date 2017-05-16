module ACH
  # Every ACH::Batch component ends with a batch control record.
  #
  # == Fields
  #
  # * record_type
  # * service_class_code
  # * entry_addenda_count
  # * entry_hash
  # * total_debit_amount
  # * total_credit_amount
  # * company_id
  # * authen_code
  # * bank_6
  # * origin_dfi_id
  # * batch_number
  class Batch::Control < Record::Base
    fields :record_type,
      :service_class_code,
      :entry_addenda_count,
      :entry_hash,
      :total_debit_amount,
      :total_credit_amount,
      :company_id,
      :authen_code,
      :bank_6,
      :origin_dfi_id,
      :batch_number
    
    defaults :record_type => BATCH_CONTROL_RECORD_TYPE,
      :authen_code        => '',
      :bank_6             => ''
  end
end
