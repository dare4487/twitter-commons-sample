module ACH
  # The +ACH::File::Reader+ class builds a corresponding +ACH::File+
  # object from a given set of data. The constructor takes an +enum+ object
  # representing a sequence of ACH lines (strings). This +enum+ object may be
  # a file handler, an array, or any other object that responds to the +#each+
  # method.
  class File::Reader
    include Constants

    # Initialize reader.
    #
    # @param [#each] enum
    def initialize(enum)
      @enum = enum
    end

    # Build a {ACH::File} object using data obtained from +@enum+ source.
    #
    # @return [ACH::File]
    def to_ach
      header_line, batch_lines, control_line = ach_data

      File.new do
        build_header header_line

        batch_lines.each do |batch_data|
          batch do
            build_header batch_data[:header]

            batch_data[:entries].each do |entry_line|
              build_entry entry_line

              if batch_data[:addendas].key?(entry_line)
                batch_data[:addendas][entry_line].each do |addenda_line|
                  build_addenda addenda_line
                end
              end
            end

            build_control batch_data[:control]
          end
        end

        build_control control_line
      end
    end

    # Process the source and return header batch and control records.
    #
    # @return [Array<ACH::Record::Base, Array>]
    def ach_data
      process! unless processed?

      return @header, batches, @control
    end
    private :ach_data

    # Process each line by iterating over strings in +@enum+ source one by one and
    # generating ACH information corresponding to record line.
    #
    # @return [true]
    def process!
      each_line do |record_type, line|
        case record_type
        when FILE_HEADER_RECORD_TYPE
          @header = line
        when BATCH_HEADER_RECORD_TYPE
          initialize_batch!
          current_batch[:header] = line
        when BATCH_ENTRY_RECORD_TYPE
          current_batch[:entries] << line
        when BATCH_ADDENDA_RECORD_TYPE
          (current_batch[:addendas][current_entry] ||= []) << line
        when BATCH_CONTROL_RECORD_TYPE
          current_batch[:control] = line
        when FILE_CONTROL_RECORD_TYPE
          @control = line
        end
      end
      @processed = true
    end
    private :process!

    # Return +true+ if +@enum+ has been processed.
    #
    # @return [Boolean]
    def processed?
      !!@processed
    end
    private :processed?

    # Iterate over +enum+ and yield first symbol of the string as
    # record type and string itself.
    def each_line
      @enum.each do |line|
        yield line[0..0].to_i, line.chomp
      end
    end
    private :each_line

    # Return array of batches in hash representation.
    #
    # @return [Array<Hash>]
    def batches
      @batches ||= []
    end
    private :batches

    # Add a new hash representation of a batch to the batch list
    # to be filled out during processing.
    #
    # @return [Array<Hash>]
    def initialize_batch!
      batches << {:entries => [], :addendas => {}}
    end
    private :initialize_batch!

    # Current (the last one) batch to fill.
    #
    # @return [Hash]
    def current_batch
      batches.last
    end
    private :current_batch

    # Current (the last one) entry string of the last batch that was processed.
    #
    # @return [String]
    def current_entry
      current_batch[:entries].last
    end
    private :current_entry
  end
end