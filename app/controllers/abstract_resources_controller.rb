require "abstracted_responder"
require "print_control"
require "resource_control"
require "parent_control"

class AbstractResourcesController < ApplicationController
  self.responder = ::AbstractedResponder
  respond_to :html, :xml, :js, :json #, :xlsx

  before_action :authenticate_user!
  before_action :set_paper_trail_whodunnit

  include PrintControl
  include ResourceControl
  include ParentControl

  before_action :set_fab_button_options
  before_action :set_variant_template
  after_action :verify_authorized
  # after_action  :manage_parenthood, only: [:create,:update,:destroy]

  # default implementation

  def prefer
    authorize resource
    if resource.prefer parent
      flash[:info] = t(:resource_preferred_correct)
      render :prefer, layout: false, status: 200 and return
    else
      flash[:error] = t(:resource_preferred_incorrect)
      render :prefer, layout: false, status: 401 and return
    end

  rescue Exception => e
    scoop_from_error e
  end

  def defer
    authorize resource
    if resource.defer parent
      flash[:info] = t(:resource_deferred_correct)
      render :defer, layout: false, status: 200 and return
    else
      flash[:error] = t(:resource_deferred_incorrect)
      render :defer, layout: false, status: 401 and return
    end

  rescue Exception => e
    scoop_from_error e
  end

  def activate
    authorize resource
    if resource.activate
      flash[:info] = t(:resource_activated_correct)
      render :activate, layout: false, status: 200 and return
    else
      flash[:error] = t(:resource_activated_incorrect)
      render :activate, layout: false, status: 401 and return
    end

  rescue Exception => e
    scoop_from_error e
  end

  def deactivate
    authorize resource
    if resource.deactivate
      flash[:info] = t(:resource_deactivated_correct)
      render :deactivate, layout: false, status: 200 and return
    else
      flash[:error] = t(:resource_deactivated_incorrect)
      render :deactivate, layout: false, status: 401 and return
    end

  rescue Exception => e
    scoop_from_error e
  end


  def attach
    authorize resource
    if resource.attach parent
      flash[:info] = t(:resource_attached_correct)
      render :attach, layout: false, status: 200 and return
    else
      flash[:error] = t(:resource_attached_incorrect)
      render :attach, layout: false, status: 401 and return
    end

  rescue Exception => e
    scoop_from_error e
  end

  def detach
    authorize resource
    if resource.detach parent
      flash[:info] = t(:resource_detached_correct)
      render :detach, layout: false, status: 200 and return
    else
      flash[:error] = t(:resource_detached_incorrect)
      render :detach, layout: false, status: 401 and return
    end

  rescue Exception => e
    scoop_from_error e
  end

  def show
    authorize resource
    respond_with resource
  rescue Exception => e
    scoop_from_error e
  end

  def new
    resource.parent_id = params[:parent_id] if resource.respond_to? :parent_id
    authorize resource
    respond_with resource
  rescue Exception => e
    scoop_from_error e
  end

  def edit
    authorize resource
    respond_with resource
  rescue Exception => e
    scoop_from_error e
  end

  def index
    authorize resource_class, :index?
    respond_with resources do |format|
      # format.xlsx {
      #   # response.headers['Content-Disposition'] = 'attachment; filename="current_tyre_stock.xlsx"'
      #   render xlsx: 'stock_items/index', template: 'current_tyre_stock', filename: "current_tyre_stock.xlsx", disposition: 'inline', xlsx_created_at: Time.now, xlsx_author: "http://wheelstore.space"
      # }
    end
  rescue Exception => e
    scoop_from_error e
  end

  def create
    authorize resource
    respond_with(resource, location: redirect_after_create ) do |format|
      if resource.save && update_parenthood
        flash[:notice] = t('.success.created', resource: resource_class.to_s )
      else
        format.html { render action: :new, status: :unprocessable_entity }
        format.js { render action: :new, status: :unprocessable_entity }
      end
    end
  rescue Exception => e
    scoop_from_error e
  end

  def update
    authorize resource
    respond_with(resource, location: redirect_after_update) do |format|
      if resource.update_attributes(resource_params) && update_parenthood
        flash[:notice] = t('.success.updated', resource: resource_class.to_s )
      else
        format.html { render action: :edit, status: :unprocessable_entity }
        format.js { render action: :edit, status: :unprocessable_entity }
      end
    end
  rescue Exception => e
    scoop_from_error e
  end

  def destroy
    authorize resource
    result = true if delete_resource && update_parenthood
    result ? (flash.now[:notice] = t('.success', resource: resource_class.to_s)) : (flash.now[:error] = t('.deleted.error',resource: resource_class.to_s) + " " + resource.errors.messages.values.join( " / "))
    if result==true
      render layout:false, status: 200, locals: { result: true }
    else
      render layout:false, status: 301, locals: { result: true, errors: resource.errors.messages.values.join( " / ") }
    end
  rescue Exception => e
    scoop_from_error e
  end

  private

    def delete_resource
      if resource.respond_to? :deleted_at
        resource.update_attributes deleted_at: Time.now
      else
        resource.destroy
      end
    end

    # you can override this on your controller
    def redirect_after_create
      resources_url {}
    end

    # you can override this on your controller
    def redirect_after_update
      resources_url {}
    end

    #
    # use views/../$action.html+mobile.erb if request originates from an iPad
    #
    def set_variant_template
      request.variant = :mobile if request.user_agent =~ /iPad/
    end


    #
    # build options for fixed action button - implement on each controller to customize
    # raise an exception
    def set_fab_button_options
      opt = { items: {}}
      case params[:action]
      when 'nothing'; opt = opt
      # when 'new';   #opt[:items].merge! print: { ajax: 'get', icon: 'print', class: 'blue lighten-2', url: '/stock_items/print?print_list=true', browser: 'new' }
      # when 'edit';  #opt[:items].merge! print: { ajax: 'get', icon: 'print', class: 'blue lighten-2', url: '/stock_items/print?print_list=true', browser: 'new' }
      # when 'show';  opt[:items].merge! print: { ajax: 'get', icon: 'print', class: 'blue lighten-2', url: '/stock_items/print', browser: 'new' }
      # when 'index'; opt[:items].merge! print: { ajax: 'get', icon: 'print', class: 'blue lighten-2', url: '/stock_items/print?print_list=true', browser: 'new' }
      end

      # = build_print_link(f.object, list: false, print_options: "print_cmd=print_label", button: 'icon-tag', text: 'Udskriv dæk label')
      @fab_button_options = opt
    end



    def scoop_from_error e

      raise e if %w{ test development }.include? Rails.env

      logger.debug "AbstractResourcesController##{params[:action]}: #{e.class}"
      a_url = root_path

      case e.class.to_s
      when "Exceptions::AuthenticationError"
        flash.now[:error] = flash[:error] = "Access Problem: <br/><small>%s</small>" % e.message
        result= false
        status = 412

      when "ActiveRecord::RecordNotFound"
        flash.now[:error] = flash[:error] = t('.fail.record_not_found')
        result = false
        status = 301
        a_url = resources_url

      when "Pundit::NotAuthorizedError"
        flash.now[:error] = flash[:error] = t('.fail.authorized', resource: resource)
        result = false
        status = 401

      when "ActiveRecord::StatementInvalid" # Mysql2::Error
        flash.now[:error] = flash[:error] = t('fail.mysql_error', mysql: e.to_s)
        result= false
        status = 409
      when "ActionView::Template::Error"
        flash.now[:error] = flash[:error] = "A template error occured - please call ALCO with: <br/><small>%s</small>" % e.message
        result= false
        status = 301

      # when "PrintJobNotCreatedError"
      #
      # when "NoPreferredPrintersFound"
      #   logit :error, 'No preferred printers found! Sending PDF by email to %s (%s) ' % [usr.name,usr.email]
      #
      # when "PrintJobResourceError"
      #   logit :error, 'PrintJob could not be created - no records!?'
      #   return false
      #
      # when "PrintJobPrinterNotAvailableError"
      #   logit :error, 'PrintJob could not be created - the user has no printers attached!!'
      #   return false



      else
        raise e
        # flash.now[:error] = flash[:error] = "An error occured - please refer to log for details!"
        # render :error, layout: false, status: 412 and return
      end

      respond_to do |format|
        case params[:action]
        when 'new'
          format.html { flash.keep(:error) ; redirect_to resources_url }
          format.js   { render :error, layout: false, status: status, locals: { result: result} }
          format.json { render json: resources, status: status }
        when 'create'
          format.html { render :new }
          format.js   { render :error, layout: false, status: status, locals: { result: result} }
          format.json { render json: resource.errors, status: status }
        when 'show'
          format.html { flash.keep(:error) ; redirect_to resources_url }
          format.js   { render :error, layout: false, status: status, locals: { result: result} }
          format.json { render json: resources, status: status }
        when 'edit'
          format.html { flash.keep(:error) ; redirect_to resources_url }
          format.js   { render :error, layout: false, status: status, locals: { result: result} }
          format.json { render json: resources, status: status }
        when 'update'
          format.html { render :edit }
          format.js   { render :error, layout: false, status: status, locals: { result: result} }
          format.json { render json: resource.errors, status: status }
        when 'index', 'destroy'
          # we should render index - but an error here will not make us happy
          # format.html { render :index }
          #
          format.html { redirect_to root_path, alert: flash[:error] }
          format.js   { render :error, layout: false, status: status, locals: { result: result} }
          format.json { render json: resources, status: status }
        else
          format.html { redirect_to a_url and return }
          format.js   { render :error, layout:false, status: status, locals: { result: result } }
        end
      end

    end

    def error_counter
      @error_counter ||= 0 
      @error_counter = @error_counter + 1
    end

end
