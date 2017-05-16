module ACH
  # Responsible for record-specific functionality for most record types,
  # handled by several subclasses. Record types handled outside this module
  # include: ACH::File::Header, ACH::File::Control, ACH::Batch::Header,
  # ACH::Batch::Control
  module Record
    extend ActiveSupport::Autoload

    autoload :Addenda
    autoload :Base
    autoload :Dynamic
    autoload :Entry
    autoload :Tail
  end
end