module ACH
  module Record
    # Base class for all record entities (e.g. +ACH::File::Header+,
    # +ACH::File::Control+, +ACH::Record::Entry+, others). Any record
    # being declared should specify its fields, and optional default values.
    # Except for +ACH::Record::Dynamic+, any declared field within a record
    # should have corresponding rule defined under +ACH::Rule::Formatter+.
    #
    # == Example
    #
    #   class Addenda < Record
    #     fields :record_type,
    #            :addenda_type_code,
    #            :payment_related_info,
    #            :addenda_sequence_num,
    #            :entry_details_sequence_num
    #     
    #     defaults :record_type => 7
    #   end
    #   
    #   addenda = ACH::Addenda.new(
    #     :addenda_type_code => '05',
    #     :payment_related_info => 'PAYMENT_RELATED_INFO',
    #     :addenda_sequence_num => 1,
    #     :entry_details_sequence_num => 1 )
    #   addenda.to_s! # => "705PAYMENT_RELATED_INFO                                                            00010000001"
    class Base
      include Validations
      include Constants

      # Raises when unknown field passed to ACH::Record::Base.fields method.
      class UnknownFieldError < ArgumentError
        # Initialize error with descriptive message.
        #
        # @param [Symbol] field
        # @param [String] class_name
        def initialize(field, class_name)
          super "Unrecognized field '#{field}' in class #{class_name}"
        end
      end

      # Raises when value of record's field is not specified and there is no
      # default value.
      class EmptyFieldError < ArgumentError
        # Initialize error with descriptive message.
        #
        # @param [Symbol] field
        # @param [ACH::Record::Base] record
        def initialize(field, record)
          super "Empty field '#{field}' for #{record}"
        end
      end

      # Specify the fields of the record. Order is important. All fields
      # must be declared in ACH::Formatter +RULES+. See class description
      # for example.
      #
      # @param [*Symbol] field_names
      # @return [Array<Symbol>]
      def self.fields(*field_names)
        return @fields if field_names.empty?
        @fields = field_names
        @fields.each{ |field| define_field_methods(field) }
      end

      # Set default values for fields. See class description for example.
      #
      # @param [Hash, nil] default_values
      # @return [Hash]
      def self.defaults(default_values = nil)
        return @defaults if default_values.nil?
        @defaults = default_values.freeze
      end

      # Define accessor methods for a given field name if it can be found
      # in the keys of {ACH::Formatter::RULES}.
      #
      # @param [Symbol] field
      # @raise [UnknownFieldError]
      def self.define_field_methods(field)
        raise UnknownFieldError.new(field, name) unless Formatter::RULES.key?(field)
        define_method(field) do |*args|
          args.empty? ? @fields[field] : (@fields[field] = args.first)
        end
        define_method("#{field}=") do |val|
          @fields[field] = val
        end
      end
      private_class_method :define_field_methods

      # Build a new instance of a record from its string representation.
      #
      # @param [String] string
      # @return [ACH::Record::Base]
      def self.from_s(string)
        field_matcher_regexp = Formatter.matcher_for(fields)
        new Hash[*fields.zip(string.match(field_matcher_regexp)[1..-1]).flatten]
      end

      # Initialize object with field values. If block is given, it will be
      # evaluated in context of isntance.
      #
      # @param [Hash] fields
      def initialize(fields = {})
        defaults.each do |key, value|
          self.fields[key] = Proc === value ? value.call : value
        end
        self.fields.merge!(fields)
        instance_eval(&Proc.new) if block_given?
      end

      # Build a string from record object.
      #
      # @return [Stirng]
      # @raise [EmptyFieldError]
      def to_s!
        self.class.fields.map do |name|
          raise EmptyFieldError.new(name, self) if @fields[name].nil?
          Formatter.format name, @fields[name]
        end.join
      end

      # Return a hash where key is the field's name and value is the field's value.
      #
      # @return [Hash]
      def fields
        @fields ||= {}
      end

      # Return field default values defined in class.
      #
      # @return [Hash]
      def defaults
        self.class.defaults
      end
      private :defaults

      # Delegate bracket-assignment to +fields+.
      #
      # @param [Symbol] name
      # @param [String] val
      # @return [String]
      def []=(name, val)
        fields[name] = val
      end
      private :[]=
    end
  end
end
