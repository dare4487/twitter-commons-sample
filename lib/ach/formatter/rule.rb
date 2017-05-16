module ACH
  # Parses string representation of rule and builds a +Proc+ based on it
  class Formatter::Rule
    # Captures formatting tokens from a rule string.
    RULE_PARSER_REGEX = /^(<-|->)(\d+)(-)?(\|\w+)?$/

    delegate :call, :[], :to => :@lambda

    attr_reader :length

    # Initialize the instance with the formatting data. Parses the given string
    # for formatting values, such as width, justification, etc. With the result,
    # it builds a Proc object to be used to format the given string according
    # to the formatting rule.
    #
    # @param [ACH::Formatter::Rule] rule
    def initialize(rule)
      just, width, pad, transf = rule.match(RULE_PARSER_REGEX)[1..-1]
      @length    = width.to_i
      @padmethod = just == '<-' ? :ljust : :rjust
      @padstr    = @padmethod == :ljust ? ' ' : pad == '-' ? ' ' : '0'
      @transform = transf[1..-1] if transf

      @lambda = Proc.new do |val|
        val = val.to_s
        (@transform ? val.send(@transform) : val).send(@padmethod, @length, @padstr)[-@length..-1]
      end
    end
  end
end
