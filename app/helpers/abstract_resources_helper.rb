module AbstractResourcesHelper

  #
  # URL Helpers
  #
  # parent

  #
  # parent returns the parent entity
  def parent
    parent? ? @parent : raise("parent will return nil - which probably was not anticipated!")
  end

  #
  # parent_class returns the class of the parent
  def parent_class
    parent? ? @parent.class : raise("parent_class will return Object - which probably was not anticipated!")
  end

  #
  # parent_name returns the name of the resource - that would be the empty string on nil's
  def parent_name
    parent? ? parent_class.to_s.pluralize.underscore : raise("parent_name will return '' - which probably was not anticipated!")
  end

  #
  # parent_url returns the parent url - /employees/1 in the /employees/1/events
  def parent_url
    parent? ? ( "/" + parent_class.to_s.pluralize.underscore + "/%s" % @parent.id) : "no_route_to_parent"
  end

  #
  # parent? will tell if a parent exists
  def parent?
    return true if (params[:parent] && params[:parent_id] && @parent = params[:parent].classify.constantize.find(params[:parent_id]))
    !(%w{NilClass TrueClass FalseClass}.include? @parent.class.to_s)
  end

  #
  # resource

  #
  # did we manage to set a resource at all?
  def resource?
    !(%w{NilClass TrueClass FalseClass}.include? @resource.class.to_s)
  end

  #
  # resource returns the current entity
  def resource
    resource? ? @resource : nil
  end

  #
  # return the name of the resource - that would be the empty string on nil's
  #
  def resource_name
    resource? ? resource.resource_name : resource_class.to_s.underscore.pluralize
  end

  #
  # resource_class is the class which the resource represent
  def resource_class
    return @resource_class if resource?
    @resource_class = params[:controller].singularize.classify.constantize
  rescue
    raise("resource_class will return Object - which probably was not anticipated!")
  end

  #
  # resource_url returns the current entity's url
  def resource_url options={}
    r=request.path
    id=params[:id]
    options = case params[:action]
      when 'create','update','delete','destroy'; ""
      else resource_options(options)
    end
    return "%s%s" % [r,options] if r.match "\/#{resource.class.to_s.tableize}\/#{id}(|\/#{params[:action]})$"
    "%s%s" % [ r.split("/#{params[:action]}")[0], options]

    # opt = {}
    # opt[:id] = options.id if options.class.ancestors.include? ActiveRecord::Base # edit_resource_url(@post)
    # opt.merge!(options) if options.class==Hash
    # opt[:action] ||= 'show'
    # opt[:id] ||= resource.id
    # opt[:controller] ||= resource_class.table_name
    # url_for opt
  end

  def resource_options options={}
    options.merge! params.except( "id", "controller", "action", "utf8", "_method", "authenticity_token" )
    options.empty? ? "" : "?" + options.collect{ |k,v| "#{k}=#{v}" }.join("&")
  end

  #
  # new_resource_url returns a new entity
  def new_resource_url(options={})
    opt = {}
    opt.merge!(options) if options.class==Hash
    opt[:controller] ||= resource_class.table_name
    opt[:action] = :new
    url_for opt
  end

  #
  # edit_resource_url returns the current entity's url for editing
  def edit_resource_url(options={})
    opt = {}
    if options.class.ancestors.include? ActiveRecord::Base # edit_resource_url(@post)
      return '' if options.id.nil? # raise "'id' value nil - cannot build edit_resource_url"
      opt[:id] = options.id
    else
      opt.merge!(options) if options.class==Hash
    end
    opt[:action] = :edit
    resource_url opt
    # opt[:id] ||= @resource.id
    # opt[:controller] ||= @resource_class.table_name
    # url_for opt
  end

  #
  # resources

  #
  # returns the current collection of entities
  def resources
    @resources
  end

  #
  # returns the resource_class pluralized - eg: stock_item => 'stock_items'
  def resources_name
    resource_name.pluralize
  end

  #
  # resources_url returns the current collection of entities' url
  def resources_url resources=@resources, options={}
    #
    # lnk = parent? ? (parent_url + "/#{resource_name}") : "/#{resource_name}"
    # lnk += options.empty? ? "" : "?" + options.collect{ |k,v| "#{k}=#{v}" }.join("&")
    options = resources if resources.class == Hash
    opt = {}
    opt.merge!(options) if options.class==Hash
    opt[:controller] ||= resource_class.table_name
    opt[:action] ||= :index
    url_for opt
  rescue
    #
    # return the root_url if no route was found!
    root_url
  end

  #
  # attach and detach resources
  def attach_url parent, resource
    '%s/%s/%s/attach' % [url_for( parent), resource.class.to_s.downcase.pluralize, resource.id]
  end

  def detach_url parent, resource
    '%s/%s/%s/detach' % [url_for( parent), resource.class.to_s.downcase.pluralize, resource.id]
  end

  #
  # activate and deactivate resources
  def activate_url resource
    '%s/activate' % url_for(resource)
  end

  def deactivate_url resource
    '%s/deactivate' % url_for( resource)
  end

  #
  # prefer and defer resources - like printers
  def prefer_url parent, resource
    '%s/%s/%s/prefer' % [url_for( parent), resource.class.to_s.downcase.pluralize, resource.id]
  end

  def defer_url parent, resource
    '%s/%s/%s/defer' % [url_for( parent), resource.class.to_s.downcase.pluralize, resource.id]
  end

  #
  # List Helpers
  def set_attached_class children, child
    return "" unless parent?
    return "" if children.nil?
    return "detached" if children.empty?
    children.include?( child) ? "" : "detached"
  end

  #
  #
  def show_resource_active item, linkable=true
    unless linkable
      if item.active
        content_tag :i, 'done', class: "material-icons small"
      else
        content_tag :i, 'pause', class: "material-icons small"
      end
    else
      if item.active
        link_to deactivate_url(item), class: 'activated green-text', title: t("deactivate_#{item.resource_name}") do
          content_tag :i, 'done', class: 'material-icons'
        end
      else
        link_to activate_url(item), class: 'deactivated red-text', title: t("activate_#{item.resource_name}") do
          content_tag :i, 'pause', class: 'material-icons'
        end
      end
    end
  end

  #
  # return a link to delete a row
  def show_resource_delete_icon item, url, lbl='name'
    link_to item, class: 'delete_link', data: { delete_title: t("delete_title"), delete_prompt: t("delete_prompt", item: t("delete_modal.#{item.class.to_s.underscore}")), delete_confirm: t("delete_confirm"), balloon: t("balloons.delete" ), balloon_pos: "left", url: url, name: "#{item.send lbl }", id: "#{item.id}", remove: "#tr-#{item.class.to_s}-#{item.id}" } do
      content_tag :i, 'delete', class: 'material-icons small'
    end
    # = link_to account, class: 'delete_link', data: { url: '/admin/accounts', name: "#{account.name}", id: "#{account.id}", remove: "#tr-#{account.id}" } do
    #   %i.material-icons.small{ title: "#{t('.delete')}"} delete

  end

  #
  def build_delete_link resource
    link_to(content_tag(:i,'delete',class:'material-icons icon-trash'), resource, class: 'btn btn-mini delete_item', :"data-no-turbolink"=>true)
  end

  #
  # return a link to print a row
  # url: ''
  # print: {template: 'what_list.html.haml', layout: 'list'|'record', range: '1,2,4-5', medium: 'printer'|'display'|'email'|'download', format: 'html'|'pdf', printer: 'name_of_printer'}
  # data: { action: '', method: '', selector: '', id: '', osv. }
  # button: 'material-icons'|false                                    either classes for a button or false => a link
  # link_layout: { text: '', title: '', icon: '' }                    text for the link - or <a..>text<i title="">icon</i></a>
  # classes: 'btn btn-mini print_item print_items ...'                jquery hooks print_item will print a specific record, print_items will print a list of records
  def build_print_link resource, options={}
    url, list, options = build_resource_url(resource,options)
    button = options.delete(:button) || false
    options[:class] = options.delete(:classes) || ( button ? 'btn btn-mini' : '')
    options[:class] += ( list ? ' print_items' : ' print_item')
    return link_to( build_button_tag(button, options), url, options) if button
    text = options.delete(:text) || t(resource_class.to_s.underscore.pluralize.to_sym)
    link_to text, url, options
  end

  # return an array url, list, options
  # options{ url: '', button: '', classes: '', text: ''}
  def build_resource_url resource, options={}
    print_options = options.delete(:print) || {}
    args = add_print_params params.merge( print: print_options)
    data_attribs = options.delete(:data) || {}
    list = print_options[:format]=='list' || false
    url = "%s/print?%s" % [ options.delete(:url) || ( !list ? url_for( resource) : url_for(resource_class.to_s.underscore.pluralize) ), args ]
    [ url, list, options.merge( data: data_attribs) ]
  end

  # return button_tag
  # text: 'what to write on the link if at all'
  # classes: 'btn btn-mini print_item print_items ...'                jquery hooks print_item will print a specific record, print_items will print a list of records
  def build_button_tag button, options={}
    layout = options.delete(:link_layout) || {}
    text = layout.delete(:text) || ''
    title = layout.delete(:title) || ''
    icon = layout.delete(:icon) || ''
    (text << content_tag(:i,icon, class: button, title: title )).html_safe
    # if text
    #   content_tag( :span) do
    #     text[1]
    #   end << content_tag(:i,text[0], class: button )
    # else
    #   content_tag(:i,text[0], class: button )
    # end
  end


  def display_base_errors resource
    return '' if (resource.errors.empty?) or (resource.errors[:base].empty?)
    messages = resource.errors[:base].map { |msg| content_tag(:p, msg) }.join
    html = <<-HTML
    <div class="alert alert-error alert-block">
      <button type="button" class="close" data-dismiss="alert">&#215;</button>
      #{messages}
    </div>
    HTML
    html.html_safe
  end

  # set_flashes will build the necessary flash
  #
  # quite stolen from bootstrap_flash
  # - but reengineered to avoid empty arrays
  def set_flashes
    flash_messages = []
    flash.each do |type, message|
      next if message.blank?
      tp = 'danger'
      tp = 'success' if [ "notice", "info" ].include? type.to_s
      message = show_flash(flash, type) if flash.kind_of? Array
      unless message.blank?
        flash[type]=nil
        text = content_tag(:div, build_close_button(tp) + message.html_safe, class: "alert fade in alert-#{tp}")
        flash_messages << text
      end
    end
    flash.clear
    flash_messages.join("").html_safe
  rescue => e
    Rails.logger.error "setting the flashes - set_flashes - failed with #{e.message}"
    ""
  end

  def divide_text(str, max_chars)
    max_chars.map do |n|
      str.lstrip!
      s = str[/^.{,#{n}}(?=\b)/] || ''
      str = str[s.size..-1]
      s
    end
  end

  def set_toasts
    toast_messages = []
    flash.each do |type, msg|
      message_arr = msg.size < 61 ? [msg] : divide_text( msg, [60,60,60,60] )
        message_arr.each do |message|
          case type
          when 'error','danger','alert'; toast_messages << "Materialize.toast('#{message}',8000, 'red darken-4');"
          when 'info'; toast_messages << "Materialize.toast('#{message}',2000, 'green lighten-3');"
          when 'success','notice'; toast_messages << "Materialize.toast('#{message}',2000, 'blue lighten-4');"
          end
        end
      end
    flash.clear
    toast_messages.join("").html_safe
  rescue => e
    Rails.logger.error "setting the toasts - set_toasts - failed with #{e.message}"
    ""
  end

  def build_close_button(type)
    "<a href='#!' class='#{type} close-notice btn-floating btn-small waves-effect waves-light' aria-hidden='true' type='button' data-dismiss='alert'><i class='material-icons'>close</i></a>".html_safe
    # link_to "#", type: "button", "aria-hidden" => "true", class: "#{type} close-notice btn-floating btn-small waves-effect waves-light", "data-dismiss" => "alert" do
    #   "<i class='material-icons'>close</i>".html_safe
    # end
  end

  #   = show_flash flash, key
  # - flash[key]=nil
  #
  def show_flash flash, key
    msg = flash[key].kind_of?( Array) ? flash[key].flatten.compact : [ flash[key] ].compact
    msg.collect!{ |m| (content_tag(:div, id: key) do m end) unless m.blank? }
    raw(msg.join)
  end

  # return a HTML fragtment containing the menu_items referring to this one
  # items is a Hash of three elements, lbl, url and possible any children
  # { item: { lbl: 'menu', url: 'menu', options: {} } }
  # { item: { lbl: 'menu', url: { item: {}, item: {} }} }
  def menu_item(items, level=0 )
    return "" if items.nil?
    str = []
    level+=1
    items.each do |k,item|
      options = item[:options] || {}
      unless item[:url].class==String
        if level>1
          str << "<li class='dropdown-submenu'>%s<ul class='dropdown-menu'>%s</ul></li>" % [ link_to( "#{item[:lbl]}", "#", options.merge(class: "dropdown-toggle", :"data-toggle"=>"dropdown")), menu_item(item[:url],level)]
        else
          str << "<li class='dropdown'>%s<ul class='dropdown-menu'>%s</ul></li>" % [ link_to( "#{item[:lbl]}<b class='caret'></b>".html_safe, "#", options.merge(class: "dropdown-toggle", :"data-toggle"=>"dropdown")), menu_item(item[:url],level)]
        end
      else
        str << "<li>%s</li>" % link_to( item[:lbl], item[:url], options )
      end
    end
    str.join( "")
  end


  # return a link - either to activate_resource_path or passify_resource_path
  # used to turn on/off any resource
  def build_active_link resource
    lbl = resource.active ? (content_tag(:i, active_popover(true)) do end) : (content_tag(:i, active_popover(false)) do end)
    link_to lbl, build_active_link_url(resource), class: "btn btn-mini active_button", remote: true, :"data-no-turbolink" => true, id: "%s_%i_actpas" % [resource.class.to_s, resource.id]
  end

  def active_msg active
    active ? "Er aktiv nu! Tryk på denne knap for at gøre denne post passiv!" : "Er passiv nu! Tryk på denne knap for at gøre denne post aktiv!"
  end

  def active_popover active
    if active
      {
          class: "icon-minus",
          rel: "popover",
          :"data-html"    => true,
          :"data-trigger" => "hover",
          :"data-title"   => "Posten er aktiv!",
          :"data-content" => "Tryk på denne knap for at gøre denne post passiv!</br/>Når poster anvendes i andre sammenhænge vil oxenServer kun tage hensyn til aktive poster!",
      }
    else
      {
          class: "icon-plus",
          rel: "popover",
          :"data-html"    => true,
          :"data-trigger" => "hover",
          :"data-title"   => "Posten er passiv!",
          :"data-content" => "Tryk på denne knap for at gøre denne post aktiv!</br/>Når poster anvendes i andre sammenhænge vil oxenServer kun tage hensyn til aktive poster!",
      }
    end
  end


  # return the url for the activate_link only
  def build_active_link_url resource
    r_url = url_for( resource)
    resource.active ? r_url + "/passify" : r_url + "/activate"
  end

  # return a link - either to attach_resource_path or detach_resource_path
  # used to attach or detach a resource to its parent
  def build_attach_link children, child
    attached = children.nil? ? false : children.include?( child)
    lbl = attached ? t(:detach) : t(:attach)
    link_to lbl, build_attach_link_url(child,attached), class: "btn btn-mini", remote: true, :"data-no-turbolink" => true, id: "%s_%i_attdet" % [child.class.to_s, child.id]
  end

  # return the url for the attach_detach_link only
  def build_attach_link_url child, attached
    path = request.path.match( /detach|attach/) ? request.path.split("/")[0..3].join("/") : request.path
    r_url = path + "/%i" % child.id
    attached ? r_url + "/detach" : r_url + "/attach"
  end

  # return a link to a new entity - possibly add route to parent
  def build_add_link lbl, cls
    r_url = cls.to_s.singularize.underscore
    r_url = parent? ? parent.class.to_s.singularize.underscore + "_" + r_url : r_url
    link_to( lbl, eval("new_%s_path" % r_url), class: 'btn btn-success')
  end

  # return a link - either to prefer_resource_path or defer_resource_path
  # used to prefer or defer a resource by its parent
  def build_prefer_link children, child
    preferred = (children.include?( child) && child.preferred?( parent))
    return oxt(:preferred) if preferred
    link_to oxt(:prefer), build_prefer_link_url(child,preferred), class: "btn btn-mini", remote: true, :"data-no-turbolink" => true, id: "%s_%i_predet" % [child.class.to_s, child.id]
  end

  # return the url for the prefer_defer_link only
  def build_prefer_link_url child, preferred
    path = request.path.match( /defer|prefer/) ? request.path.split("/")[0..3].join("/") : request.path
    r_url = path + "/%i" % child.id
    preferred ? r_url + "/defer" : r_url + "/prefer"
  end

  def add_print_params p, prefix=""
    args = []
    p.each do |k,v|
      k = "#{prefix}[#{k}]" unless prefix.blank?
      if v.is_a? Hash
        args << add_print_params( v, 'print')
      else
        args << "#{k}=#{v}" unless %w{ ids action controller}.include? k
      end
    end
    args.join("&")
  end

  def build_toggle_white_collar_url
    if params[:blue_collar].nil?
      link_to oxt(:kun_timelønnede), collection_url(blue_collar: true), class: "btn btn-info"
    else
      link_to oxt(:alle_medarbejdere), collection_url, class: "btn btn-info"
    end
  end


  # return a link to print a label for a row
  # url: ''
  # list: true|false
  # template: 'what_list.html.haml',
  # button: true|false                                                either a button or a link
  # classes: 'btn btn-mini print_item print_items ...'                jquery hooks print_item will print a specific record, print_items will print a list of records
  def build_label_link resource, options={}

    list = options.delete(:list) || false
    button = options.delete(:button) || true
    url = options.delete(:url) || ( !list ? url_for( resource) + "/label" : url_for(resource_class.to_s.underscore.pluralize) + "/label?print_list=true&#{add_print_params}" )
    classes = options.delete(:classes) || ( button ? 'btn btn-mini' : '')

    return link_to(content_tag(:i,nil,class:'icon-tag'), url, class: classes, target: '_new') if button
    link_to oxt(resource_class.to_s.underscore.pluralize.to_sym), url, options.merge( class: classes, target: '_new')

  end

  #
  # set title of breadcrumb
  #
  def breadcrumb_title( str )
    str.index( 'title="translation missing' ) ? str : str.mb_chars.upcase
  rescue
    str
  end

  #
  # show_page_title
  # does a resource_class and action based translation of title on a page
  #
  def show_page_title
    # t '%s.%s.title' % [ resource_class.table_name, params[:action] ]
    t '%s.%s.title' % [ params[:controller], params[:action] ]
  end

  #
  # show_lbl is used on every show.html.haml to build the label
  #
  def show_lbl key
    content_tag :b, "#{key}: "
  end

  #
  # on imprint_certificate.html.haml
  def show_product_logo product_logo
    case product_logo
    when /.jpg/, /.png/
      tag(:img, { class: "product_logo", src: "#{Rails.root}/app/assets/images/#{product_logo}" }, false)
    else
      product_logo
    end
  end

  #
  # when sorting rows
  # set_direction will flip ASC and DESC
  def set_direction dir
    return 'ASC' unless dir
    dir == 'ASC' ? 'DESC' : 'ASC'
  end

  #
  # column_header sets a table header (TH) optionally with necessary data for balloon text and sorting
  # options: balloon: "", balloon_pos: "", role: "", direction: "", field: ""
  #
  # bare minimum is
  #   column_header :some_field  - which will be translated, using the tables.headers.some_field.label
  #   (if you need a different "label", identify the sorting field by an field: table_field)
  #
  # adding class's to managing styling
  #   column_header :some_field, class: ""
  #
  # adding sorting
  #   column_header :some_field, role: "sort",

  # adding balloon helptext
  #   column_header :some_field, balloon: true
  #   ( set the text to fixed with balloon: "FIXED TEXT - NOT TRANSLATED")
  #   ( set position with balloon_pos: "left")
  #
  def column_header field, options={}
    options[:data] ||= {}
    # role = (options.delete :role) || ''
    # classes = (options.delete :class) || ''
    # id = (options.delete :id) || nil
    balloon = (options.delete :balloon) || false
    if balloon
      options[:data][:balloon] = (balloon.class==String) ? balloon : I18n.translate("tables.headers.#{field}.balloon")
      options[:data][:balloon_pos] = (options.delete :balloon_pos) || "up"
      options[:data][:balloon_length] = (options.delete :balloon_length) || "fit"
    end
    options[:data][:field] = (options.delete :field) || field
    options[:data][:direction] = (options.delete :direction) || @sorting_direction
    # txt = []
    content_tag :th, options do
      if options[:role] && options[:role]=="sort"
        mark_sorted options[:data][:field], I18n.translate( "tables.headers.#{field}.label")
      else
        I18n.translate( "tables.headers.#{field}.label")
      end
    end
  end

  #
  # mark_sorted will set a class depending on whether this column is sorted on
  def mark_sorted col, label
    if request.params[:s] == col
      (
        content_tag( :span, label, class: "th-label-sort-by") +
        (content_tag :i, class: "material-icons" do
          (request.params[:d]=='DESC' ? "arrow_drop_down" : "arrow_drop_up") rescue "arrow_drop_up"
        end)
      ).html_safe
    else
      content_tag :span, label, class: "th-label"
    end
  rescue
    content_tag :span, label, class: "th-label"
  end


end
