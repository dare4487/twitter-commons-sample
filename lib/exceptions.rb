# encoding: UTF-8
#/* - - - - - - - - - - - - - - - - - - - - -
#
#   Title : WEB Appliances Crest Inc, Web Form Framework
#   Author : Enrique Phillips
#   URL : http://www.wac.bz
#
#- - - - - - - - - - - - - - - - - - - - - */
module Exceptions

  class OxenStandardError < StandardError
    attr_reader :query, :record, :policy

    def initialize(options = {})
      if options.is_a? String
        message = options
      else
        # @query  = options[:query]
        # @record = options[:record]
        # @policy = options[:policy]
        #
        message = options.fetch(:message) { "OXEN says: no reason was given - error class is %s" % self.class.to_s }
      end

      super(message)
    end
  end

  class NoContextFound < OxenStandardError; end
  class NoPreferredPrintersFound < OxenStandardError; end
  class WhatAnError < OxenStandardError; end

  class MethodOrClassNotImplementedError < StandardError; end

  class AuthenticationError < OxenStandardError; end
  class InvalidUsername < OxenStandardError; end
  class UserNotLoggedIn < OxenStandardError; end

  class DataInputError < OxenStandardError; end
  class ParameterNotHashError < OxenStandardError; end
  class ParameterArrayEmptyError < OxenStandardError; end
  class ParameterHashEmptyError < OxenStandardError; end
  class ParameterNotOxError < OxenStandardError; end

  class DeleteActionNotAllowedError < OxenStandardError; end

  class EventParseError < OxenStandardError; end
  class EventNotParsedYetError < OxenStandardError; end
  # class RecurrenceParseError < StandardError; end

  class TranslatorError < OxenStandardError; end

  class PrintJobRenderingError < OxenStandardError; end
  class PrintJobPrintingError < OxenStandardError; end
  class PrintJobResourceError < OxenStandardError; end
  class PrintJobPrinterNotAvailableError < OxenStandardError; end

  class ExcludedInstanceAllreadyGoneError < OxenStandardError; end
  class IncludedInstanceAllreadyHereError < OxenStandardError; end

  class MovingFileFailedError < OxenStandardError; end


end
