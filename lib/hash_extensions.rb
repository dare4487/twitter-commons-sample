class Hashit
  def initialize(hash, node_name=nil)
    if !node_name.nil?
      self.instance_variable_set("@_node_name", node_name)
      self.class.send(:define_method, "_node_name", proc{self.instance_variable_get("@_node_name")}) if !self.respond_to?("_node_name")
      self.class.send(:define_method, "_node_name=", proc{|node_name| self.instance_variable_set("@_node_name", node_name)}) if !self.respond_to?("_node_name=")
    end
    hash.each do |k,v|
      self.instance_variable_set("@#{k}", v.is_a?(Hash) ? Hashit.new(v, k) : v)
      self.class.send(:define_method, k, proc{self.instance_variable_get("@#{k}")}) if !self.respond_to?("#{k}")
      self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)}) if !self.respond_to?("#{k}=")
    end
  end
end
