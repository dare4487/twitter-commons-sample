class AncestryAbstractResource < AbstractResource
  self.abstract_class=true

  #
  # provided for ancestry 'polluted' tables ;)
  #
  # children and subtree are special ancestry related methods
  #
  # # # #
  def self.arraying(options={}, hash=nil)
    hash ||= arrange(options)

    arr = []
    hash.each do |node, children|
      arr << node
      arr += arraying(options, children) unless children.nil?
    end
    arr
  end

  def possible_parents order='name'
    parents = self.arraying( order: order)
    return new_record? ? parents : parents - subtree
  end
  # # # #
  #
end
