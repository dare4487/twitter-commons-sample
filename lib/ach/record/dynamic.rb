module ACH
  module Record
    # Descendants of +ACH::Record::Dynamic+ class are the only
    # records allowed to have previously undefined fields. However,
    # each new field definition requires a rule string to be passed.
    # +UndefinedFormatError+ will be raised otherwise. If the field
    # has already been defined, and a new rule string is passed,
    # a +DuplicateFormatError+ is raised.
    #
    # == Example
    #
    #   class CustomHeader < ACH::Record::Dynamic
    #     request_type '<-9-' => '$$ADD ID='
    #     remote_id    '<-8-'
    #     file_type    '<-6-', 'NWFACH'
    #   end
    #
    # This example declares a +CustomHeader+ record type with following
    # fields:
    # * +request_type+, defined by rule '<-9-' with a default
    # value of '$$ADD ID='
    # * +remote_id+ with no default value
    # * +file_type+ with default value of 'NWFACH'
    #
    # Note: passing two arguments to method call is equivalent to
    # passing a hash with a single key-value pair.
    class Dynamic < Base
      # Error raised on re-definition of Dynamic record.
      class DuplicateFormatError < ArgumentError
        # Initialize error with descriptive message.
        #
        # @param [Symbol] field_name
        def initialize(field_name)
          super "Rule #{field_name} has already been defined"
        end
      end

      # Error raised if dynamic record is declared first time without
      # format specified.
      class UndefinedFormatError < ArgumentError
        # Initialize error with descriptive message.
        #
        # @param [Symbol] field_name
        def initialize(field_name)
          super "Unknown field #{field_name} should be supplied by format"
        end
      end

      # For a dynamic record, analyze any unknown message as a pattern for
      # new Rule, and define it for future usage on match.
      #
      # @param [Symbol] field
      # @param [*Object] args
      # @raise [UndefinedFormatError]
      # @raise [DuplicateFormatError]
      def self.method_missing(field, *args)
        format, default = args.first.is_a?(Hash) ? args.first.first : args
        unless format =~ Formatter::Rule::RULE_PARSER_REGEX
          default, format = format, nil
        end
        
        unless Formatter.defined? field
          raise UndefinedFormatError.new(field) if format.nil?
          Formatter.define field, format
        else
          raise DuplicateFormatError.new(field) if format
        end
        define_field_methods(field)
        (@fields ||= []) << field
        (@defaults ||= {})[field] = default if default
      end
    end
  end
end