require 'active_support/concern'

module ParentControl
  extend ActiveSupport::Concern

  included do
    before_filter :set_parents, only: [ :new, :edit, :show ]
  end

  def parent
    @parent ||= find_parent
  end


  def parent_class
    @parent_class ||= @parent.class
  end

  def parent_class= val
    @parent_class = val
  end

  def parent?
    !(%w{NilClass TrueClass FalseClass}.include? parent.class.to_s)
  end

  #
  # parent_url returns the parent url - /employees/1
  def parent_url options={}
    parent? ? url_for(@parent) : ""
    # parent? ? ( "/%s/%s" % [ @parent.class.table_name, @parent.id ] ) : ""
  rescue Exception => e
    scoop_from_error e
  end


  #
  # build an array of the resource - particular to <SELECT>
  def set_parents
    @parents = []
    return @parents unless resource_class.respond_to? :roots #( 'arraying') && resource? )
    @parents = resource_class.arraying({ order: 'name'}, resource.possible_parents)
  rescue Exception => e
    scoop_from_error e
  end


  #
  #
  # /employees/1/teams
  # /employees/1/teams/5
  # /employees/1/teams/5/attach
  # /theatres/2/contacts/5/uris.js
  def find_parent path=nil, parms=nil
    path ||= request.path
    parms ||= params
    if parms[:parent].nil? #or params[:parent_id].nil?
      paths=path.split("/")
      paths.pop if %w{new edit show create update delete index}.include? paths[-1]
      return nil if (paths.size < 3) #or (paths.size==4 and %w{edit new}.include?( parms[:action]))
      recognise_path paths.join("/")
    else
      parms[:parent].classify.constantize.find(parms[:parent_id])
    end
  end
  #
  # ['theatres','5','contacts','2','uris.js']
  def recognise_path path
    path_elements = Rails.application.routes.recognize_path path.gsub /\..*$/,''   # "/admin/users/2/printers/3/attach" => {:controller=>"printers", :action=>"attach", :user_id=>"2", :id=>"3"}
    recognise_parent( recognise_resource( path_elements ) )

  rescue Exception => e
    nil
    # return [ nil, nil, false ] if e.class.to_s == "ActionController::RoutingError"

  end

  # {:controller=>"printers", :action=>"attach", :user_id=>"2", :id=>"3"}
  def recognise_resource elems
    resource_class = elems.delete(:controller).singularize.classify.constantize
    resource = resource_class.find( elems.delete(:id) )
    elems
  rescue Exception => e
    return elems if e.class.to_s == "ActiveRecord::RecordNotFound"
    resource_class = nil
    elems
  end

  # { :action=>"attach", :user_id=>"2" }
  def recognise_parent elems
    elems.delete :action
    arr = elems.keys.first.to_s.split("_")
    return nil unless arr.include? "id"
    arr.pop
    arr.join("_").singularize.classify.constantize.find(elems.values.first)
  rescue
    nil
  end

  #
  # # /employees/1/teams/new
  # # /employees/1/teams/1/edit
  # # /employees/1/teams/1/delete
  def update_parenthood
    if params[:parent] and params[:parent_id]
      # raise "Ups - is this ready for prime time yet?"
      parent = params[:parent].classify.constantize.find(params[:parent_id])
      unless parent.blank?
        case params[:action]
        when "create"
          children = eval("parent.#{resource_name}")
          children << resource unless children.include? resource
        # when "edit"
        when "delete"
          children = eval("parent.#{resource_name}")
          children >> resource
        end
      end
    end
    true
  rescue
    false
  end
  #
  #

end
