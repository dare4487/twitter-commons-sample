require 'active_support/concern'
require 'active_support/dependencies/autoload'
require 'active_support/inflector'
require 'active_support/ordered_hash'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/class/attribute'

require "ach/version"

# Support for building the files necessary for the bulk exchange of debits and
# credits with financial institutions via the Automated Clearing House system,
# governed by NACHA ( http://www.nacha.org/ ).
module ACH
  extend ActiveSupport::Autoload

  autoload :Constants
  autoload :Formatter
  autoload :Validations
  autoload :Component
  autoload :Record
  autoload :Batch
  autoload :File

  # For a given string, try to locate the corresponding constant
  # (apparently Class) under the {ACH} or {ACH::Record} modules.
  #
  # @param [String] name
  # @return [Object]
  def self.to_const(name)
    [self, self::Record].detect{ |mod| mod.const_defined?(name) }.const_get(name)
  end
end
