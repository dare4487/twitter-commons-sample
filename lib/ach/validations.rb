module ACH
  # This module hosts the most basic validations for both +components+ and
  # +records+. The only validation being performed is presence validation.
  module Validations
    # Clear errors, validate object and return +true+ if records are empty.
    #
    # @return [Boolean]
    def valid?
      reset_errors!
      is_a?(Component) ? validate_as_component : validate_as_record
      errors.empty?
    end

    # If +self+ is an instance of +Component+ sublclass, validation process
    # will accumulate errors of nested records under corresponding keys to
    # provide better readability.
    def validate_as_component
      counts = Hash.new(0)
      to_ach.each do |record|
        unless record.valid?
          klass = record.class
          errors["#{klass}##{counts[klass] += 1}"] = record.errors
        end
      end
    end
    private :validate_as_component

    # If +self+ is instance of +Record+, the only records validated are
    # missing values of required fields.
    def validate_as_record
      self.class.fields.each do |field|
        errors[field] = "is required" unless fields[field]
      end
    end
    private :validate_as_record

    # Return +errors+ hash.
    #
    # @return [ActiveSupport::OrderedHash]
    def errors
      @errors || reset_errors!
    end

    # Set +@errors+ as brand new instance of ordered hash.
    #
    # @return [ActiveSupport::OrderedHash]
    def reset_errors!
      @errors = ActiveSupport::OrderedHash.new
    end
    private :reset_errors!
  end
end
