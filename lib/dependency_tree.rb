=begin
    Defines a simple dependency tree in a has map and allows accessing top and GlobalConstants::NEXT item in the tree.
    - The keys 'GlobalConstants::NEXT, GlobalConstants::PREVIOUS and GlobalConstants::PROJECTNAME_NAME' are self-descriptive and symbols
    - GlobalConstants::IS_ROOT's project GlobalConstants::PREVIOUS is always nil, so are all leaf node GlobalConstants::NEXT
    {
        "Ontology" => {
            "GlobalConstants::PROJECTNAME" => "Ontology", 
            "GlobalConstants::IS_ROOT" => "y", 
            "GlobalConstants::NEXT" => "FhirWalker", 
            "GlobalConstants::PREVIOUS" => nil, 
            "metadata" => "[json or another hash]" 
        },
        "FhirWalker" => {
            "GlobalConstants::PROJECTNAME" => "Portal", 
            "GlobalConstants::NEXT" => "EventTracking", 
            "GlobalConstants::PREVIOUS" => "Ontology", 
            "metadata" => "[json or another hash]" 
        }
    }
=end


class DependencyTree

  def initialize dependency_map
    @dependency_map = dependency_map
    @root_node = nil
  end

  def root
    return nil if @dependency_map.nil? || !@dependency_map.is_a?(GlobalConstants::HASH) || @dependency_map.empty?
    return @root_node if !@root_node.nil?

    @dependency_map.each do |k,v| 
      if v.has_key?(GlobalConstants::IS_ROOT) && v[GlobalConstants::IS_ROOT].downcase == 'y'
        root_node = Hashit.new v, k
        @root_node = root_node
        return @root_node
      end
    end
  end

  def next_node current
    return nil if current.to_s.strip.length == 0
    return nil if @dependency_map.nil? || !@dependency_map.is_a?(GlobalConstants::HASH) || @dependency_map.empty?

    if @dependency_map[current].has_key? GlobalConstants::NEXT
      next_node_name = @dependency_map[current][GlobalConstants::NEXT]
      next_node = @dependency_map[next_node_name]
      return nil if next_node.nil?
      return Hashit.new next_node, next_node_name
    end
  end

  def previous_node current
    return nil if current.to_s.strip.length == 0
    return nil if @dependency_map.nil? || !@dependency_map.is_a?(GlobalConstants::HASH) || @dependency_map.empty?

    if @dependency_map[current].has_key? GlobalConstants::PREVIOUS
      prev_node_name = @dependency_map[current][GlobalConstants::PREVIOUS]
      prev_node = @dependency_map[prev_node_name]
      return nil if prev_node.nil?
      return Hashit.new prev_node, prev_node_name
    end
  end

  def traverse
    current = root
    yield current
    while current != nil
      begin
        current = next_node current._node_name
      rescue
        #puts $!
        current = nil
      end
      yield current if !current.nil?
    end
  end

end
