module ACH
  module Record
    # Since a number of records in ACH file must be multiple of 10, tail records
    # are used to populate empty records at the end of the file with "9" characters.
    class Tail < Base
      fields :nines
      defaults :nines => '9' * RECORD_SIZE
    end
  end
end
