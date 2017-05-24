require 'active_support/concern'

module ResourceControl
  extend ActiveSupport::Concern

  included do

    before_action :set_resource #, except: :index
    before_action :set_resources, only: [:index, :print]

  end

  def resource_params
    raise 'You need to "def resource_params" on the %sController! (see: http://blog.trackets.com/2013/08/17/strong-parameters-by-example.html)' % params[:controller].capitalize
  end

  def set_resource
    parent
    resource
  end

  def set_resources
    resources
  end

  def resource?
    !(%w{NilClass TrueClass FalseClass}.include? @resource.class.to_s)
  rescue Exception => e
    scoop_from_error e
  end

  def resource
    @resource ||= (_id.nil? ? new_resource : resource_class.find(_id) )
    return @resource if @resource.nil?
    @resource.current_user = (current_user || nil) if @resource.respond_to? :current_user
    @resource
  rescue Exception => e
    scoop_from_error e
  end

  # def resource=val
  #   @resource=val
  # end

  def new_resource
    return nil if resource_class.nil?
    return resource_class.new if resource_class.ancestors.include?( ActiveRecord::Base ) and !(params.include? resource_class.to_s.underscore) #[ 'create', 'update' ].include? params[:action]
    p = resource_params
    p=p.compact.first if p.class==Array
    return resource_class.new(p.merge(current_user: current_user)) if resource_class.ancestors.include? ActiveRecord::Base
    nil
  rescue Exception => e
    scoop_from_error e
  end

  def _id
    return nil if !params[:id] || params[:id]=="0"
    params[:id] || params["#{resource_class.to_s.downcase}_id".to_sym]
  rescue Exception => e
    scoop_from_error e
  end

  def resource_name options={}
    resource_class.table_name
  rescue Exception => e
    scoop_from_error e
    # resource_class.to_s.underscore.pluralize
  end

  def resource_class
    return @resource_class if resource?
    @resource_class ||= params[:controller].singularize.classify.constantize
  rescue Exception => e
    scoop_from_error e
  end

  def resource_class= val
    @resource_class = val
  end

  #
  #
  # return the resources collection - preferably from the cache
  def resources options={}
    @resources ||= find_resources options
  end


  #
  # returns the url for the resource - like /users/1
  def resource_url options={}
    r=request.path
    id=params[:id]
    options = case params[:action]
      when 'create','update','delete','destroy'; ""
      else resource_options(options)
    end
    return "%s%s" % [r,options] if r.match "#{resource.class.to_s.tableize}\/#{id}$"
    "%s%s" % [ r.split("/#{params[:action]}")[0], options]
  rescue Exception => e
    scoop_from_error e
  end


  #
  # returns the url for the resources - /employees or /employees/1/events
  def resources_url options={}
    r=request.path
    options = case params[:action]
      when 'create','update','delete','destroy'; ""
      else resource_options(options)
    end
    return "%s%s" % [r,options] if r.match "#{resource.class.to_s.tableize}$"
    "%s%s%s" % [ r.split( resource.class.to_s.tableize)[0],resource.class.to_s.tableize, options]
  rescue Exception => e
    scoop_from_error e
  end

  def resource_options options={}
    options.merge! params.except( "id", "controller", "action", "utf8", "_method", "authenticity_token" )
    options.empty? ? "" : "?" + options.collect{ |k,v| "#{k}=#{v}" }.join("&")
  end

  #
  # find the resources collection
  def find_resources options

    # return [] unless resource_class.ancestors.include? ActiveRecord::Base
    params[:ids] ||= []
    params[:ids] << params[:id] unless params[:id].nil?

    if params[:ids].compact.any?
      policy_scope(resource_class).where(id: params[:ids].compact.split(",").flatten)
    else
      # search
      r = _search options

      # filter
      r = _filter r, options

      # sort
      r = _sort r, options

      # paginate
      r = _paginate r

      # (params[:format].nil? or params[:format]=='html') ? r.page(params[:page]).per(params[:perpage]) : r
    end
  end

  #
  # search - it at all
  #
  def _search options
    if params[:q].blank? #or params[:q]=="undefined"
      parent? ? parent.send(resource_name) : (resource_class.nil? ? nil : find_all_resources(options))
    else
      find_resources_queried options
    end
  end

  #
  # filter - it at all
  #
  def _filter r, options
    return r if params[:f].blank?
    return resource_class.filter r, params[:f], options if resource_class.respond_to? :filter
    r
  end

  #
  # sort - it at all
  #
  # %th{ role:"sort", data{ field: "*barcode", direction: "DESC"} }
  # $('th[role="sort"]')
  def _sort r, options
    r.order "%s %s" % [ (params[:s] || "id"), sorting_direction(params[:d]) ]
  end

  def sorting_direction val=nil
    _flip(val || @sorting_direction)
  end

  def _flip val
    @sorting_direction = (val == "ASC" ? "DESC" : "ASC")
    val
  rescue
    @sorting_direction = "ASC"
  end

  #
  # paginate - it at all
  #
  def _paginate r
    return r if params[:action]=='print'
    # will it obey the #page call?
    # is it without format or html or scrolling or with search?
    if (r.respond_to?( :page)) && (params[:format].nil? or params[:format]=='html' or params[:scrolling] or params[:s])
      params[:perpage] ||= 20
      params[:page] ||= 1
      return r.page(params[:page]).per(params[:perpage])
    else
      return r
    end
  end

  #
  # find queried resources collection - implement on each controller to customize
  # raise an exception
  def find_all_resources options
    policy_scope(resource_class)
  end

  #
  # find queried resources collection - implement on each controller to customize
  # raise an exception
  def find_resources_queried options
    case params[:f]
    when nil
      if parent?
        policy_scope(resource_class).tags_included?( params[:q].split(" ") ).where( options )
      else
        policy_scope(resource_class).tags_included?( params[:q].split(" ") )
      end
    else
      policy_scope(resource_class)
    end
  end

  class_methods do
  end

end
