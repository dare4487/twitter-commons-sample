module ACH
  # An ACH::File::Header record is the first record of every ACH::File
  # (in case the ACH::File::TransmissionHeader record is absent).
  #
  # == Fields:
  #
  # * record_type
  # * priority_code
  # * immediate_dest
  # * immediate_origin
  # * date
  # * time
  # * file_id_modifier
  # * record_size
  # * blocking_factor
  # * format_code
  # * immediate_dest_name
  # * immediate_origin_name
  # * reference_code
  class File::Header < Record::Base
    fields :record_type,
      :priority_code,
      :immediate_dest,
      :immediate_origin,
      :date,
      :time,
      :file_id_modifier,
      :record_size,
      :blocking_factor,
      :format_code,
      :immediate_dest_name,
      :immediate_origin_name,
      :reference_code
    
    defaults :record_type => FILE_HEADER_RECORD_TYPE,
      :priority_code      => 1,
      :date               => lambda{ Time.now.strftime("%y%m%d") },
      :time               => lambda{ Time.now.strftime("%H%M") },
      :file_id_modifier   => 'A',
      :record_size        => RECORD_SIZE,
      :blocking_factor    => BLOCKING_FACTOR,
      :format_code        => FORMAT_CODE,
      :reference_code     => ''
  end
end
