module ACH
  # Hosts functionality required to append +TransmissionHeader+ to a file.
  # +TransmissionHeader+ is optional and inherited from <tt>ACH::Record::Dynamic</tt>
  # class, which means it may have variable number of fields with custom formatting.
  # +TransmissionHeader+ may be defined only once per file. You may specify default
  # value for custom fields during definition
  #
  # == Example
  #
  #   class MyFile < ACH::File
  #     trasmission_header do
  #       starting      '->1' => '<'
  #       receiver_name '->10'
  #       ending        '->1' => '>'
  #     end
  #     # other definitions
  #   end
  #   
  #   file = MyFile.new do
  #     receiver_name 'MY PROVIDER'
  #   end
  module File::TransmissionHeader
    extend ActiveSupport::Concern

    # Raised when (descendant of) ACH File tries to redeclare it's +TransmissionHeader+.
    class RedefinedTransmissionHeaderError < RuntimeError
      # Initialize error with descriptive message.
      def initialize
        super "TransmissionHeader record may be defined only once"
      end
    end

    # Raised when +TransmissionHeader+ is declared with no fields in it
    class EmptyTransmissionHeaderError < RuntimeError
      # Initialize error with descriptive message.
      def initialize
        super "Transmission_header should declare it's fields"
      end
    end

    # Class macros.
    module ClassMethods
      # Defines and declares +TransmissionHeader+ class within scope of +self+.
      #
      # @return [Boolean]
      # @raise [RedefinedTransmissionHeaderError]
      # @raise [EmptyTransmissionHeaderError]
      def transmission_header(&block)
        raise RedefinedTransmissionHeaderError if have_transmission_header?

        klass = Class.new(Record::Dynamic, &block)

        raise EmptyTransmissionHeaderError if klass.fields.nil? || klass.fields.empty?

        const_set(:TransmissionHeader, klass)
        @have_transmission_header = true
      end

      # Returns +true+ if +TransmissionHeader+ is defined within scope of the class.
      #
      # @return [Boolean]
      def have_transmission_header?
        @have_transmission_header
      end
    end

    # Helper instance method. Returns +true+ if +TransmissionHeader+ is defined within
    # scope of it's class.
    #
    # @return [Boolean]
    def have_transmission_header?
      self.class.have_transmission_header?
    end

    # Builds +TransmissionHeader+ record for self. Yields it to +block+, if passed.
    # Returns nil if no +TransmissionHeader+ is defined within scope of class.
    #
    # @param [Hash] fields
    # @return [ACH::File::TransmissionHeader]
    def transmission_header(fields = {})
      return nil unless have_transmission_header?

      merged_fields = fields_for(self.class::TransmissionHeader).merge(fields)

      @transmission_header ||= self.class::TransmissionHeader.new(merged_fields)
      @transmission_header.tap do |head|
        head.instance_eval(&Proc.new) if block_given?
      end
    end
  end
end