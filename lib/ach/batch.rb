module ACH
  # Represents an ACH::Component, which is located under ACH::File and
  # contains a variable number of ACH::Record::Entry and ACH::Record::Addenda
  # records itself.
  class Batch < Component
    autoload :Builder
    autoload :Control
    autoload :Header

    include Builder

    has_many :entries
    has_many :addendas, :linked_to => :entries
  end
end
