module ACH
  module Record
    # A subclass of ACH::Record::Base, an Entry appears in an ACH::Batch
    # component. It is the main record for representing a particular
    # transaction.
    #
    # == Fields
    #
    # * record_type
    # * transaction_code
    # * routing_number
    # * bank_account
    # * amount
    # * customer_acct
    # * customer_name
    # * transaction_type
    # * addenda
    # * bank_15
    class Entry < Base
      # List of digits that Credit transaction code should start from.
      CREDIT_TRANSACTION_CODE_ENDING_DIGITS = ('0'..'4').to_a.freeze

      fields :record_type,
        :transaction_code,
        :routing_number,
        :bank_account,
        :amount,
        :customer_acct,
        :customer_name,
        :transaction_type,
        :addenda,
        :bank_15

      defaults :record_type => BATCH_ENTRY_RECORD_TYPE,
        :transaction_code   => 27,
        :transaction_type   => 'S',
        :customer_acct      => '',
        :addenda            => 0,
        :bank_15            => ''

      # Return +true+ if +self+ is not a credit record.
      #
      # @return [Boolean]
      def debit?
        !credit?
      end

      # Return +true+ if the second digit of a value of the +transaction_code+ field
      # is one of +CREDIT_TRANSACTION_CODE_ENDING_DIGITS+.
      #
      # @return [Boolean]
      def credit?
        CREDIT_TRANSACTION_CODE_ENDING_DIGITS.include? transaction_code.to_s[1..1]
      end
    end
  end
end
