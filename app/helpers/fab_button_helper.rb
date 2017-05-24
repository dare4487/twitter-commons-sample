module FabButtonHelper

  # FAB
  # Fixed Action Button
  def build_fab_button options={}
    list = <<LISTEND
    <li><a class="btn-floating red"><i class="material-icons">insert_chart</i></i></a></li>
    <li><a class="btn-floating yellow darken-1"><i class="material-icons">format_quote</i></a></li>
    <li><a class="btn-floating green"><i class="material-icons">publish</i></a></li>
    <li><a class="btn-floating blue"><i class="material-icons">attach_file</i></a></li>
LISTEND

    button = '<a class="btn-floating btn-large blue"> <i class="large material-icons">mode_edit</i> </a>'
    menu = '<div class="fixed-action-btn" style="bottom: 45px; right: 24px;">%s <ul> %s </ul> </div>'

    options[:button] ||= button
    options[:list] ||= list
    options[:menu] ||= menu
    (options[:menu] % [ options[:button], options[:list]]).html_safe
  end

  def fab_button_options
    @fab_button_options ||= {} #raise "fab_button_options nil - not what you intended, I guess?!"
  end
  # do a 'before_action :set_fab_button_options (that returns a Hash with
  # list elements like:
  #   { items: { print: { ajax: 'get', icon: 'list', class: 'blue lighten-2', url: '/stock_items/print?print_list=true' } } })',
  # add a special build_fab_options on your project - or use this default one
  #
  #
  # AJAX: <a data-ajax="post" data-remote="false" data-url="%s" class="btn-floating green"><i class="material-icons">publish</i></a>
  #
  def build_fab_options resource, options={}
    lst = []
    # if items are empty - dream them up
    options[:items] ||= {}
    options[:items].merge!( list: { ajax: 'get', icon: 'list', class: 'blue', url: resources_url(resources, controller: params[:controller]), oxremote: 'false'  }){ |key, v1, v2| v1 }

    case options[:action]
    when 'new','create'
      options[:items].merge!( reset: { action: 'reset', icon: 'undo', class: 'orange darken-2' }){ |key, v1, v2| v1 }
      options[:items].merge!( publish: { ajax: 'post', icon: 'publish', class: 'green', url: resources_url(resources, controller: params[:controller]), oxremote: 'false' }){ |key, v1, v2| v1 }

      options[:button] ||= "<a class='btn-floating btn-large green'><i class='large material-icons'>publish</i> </a>"

    when 'show'
      options[:items].merge!( add: { ajax: 'get', icon: 'add', class: 'green lighten-1', url: new_resource_url, oxremote: 'false' }){ |key, v1, v2| v1 }
      options[:items].merge!( edit: { ajax: 'get', icon: 'edit', class: 'yellow darken-2', url: edit_resource_url(resource), oxremote: 'false' }){ |key, v1, v2| v1 }
      options[:items].merge!( delete: { ajax: 'delete', icon: 'delete', class: 'red darken-1', url: resources_url, id: resource.id, oxremote: 'false' }){ |key, v1, v2| v1 }

      options[:button] ||= "<a class='btn-floating btn-large blue'><i class='fab-button large material-icons'>edit</i> </a>"

    when 'edit', 'update'
      options[:items].merge!( add: { ajax: 'get', icon: 'add', class: 'green lighten-1', url: new_resource_url , oxremote: 'false'}){ |key, v1, v2| v1 }
      options[:items].merge!( publish: { ajax: 'post', icon: 'publish', class: 'green', url: resource_url, oxremote: 'false' }){ |key, v1, v2| v1 }
      options[:items].merge!( delete: { ajax: 'delete', icon: 'delete', class: 'red darken-1', url: resources_url, id: resource.id, oxremote: 'false' }){ |key, v1, v2| v1 }

      options[:button] ||= "<a class='btn-floating btn-large green'><i class='large material-icons'>publish</i> </a>"

    when 'index'
      options[:items].merge!( add: { ajax: 'get', icon: 'add', class: 'green lighten-1', url: new_resource_url(controller: params[:controller]), oxremote: 'false' }){ |key, v1, v2| v1 }

      options[:button] ||= "<a class='btn-floating btn-large blue'><i class='fab-button large material-icons'>mode_edit</i> </a>"

    end

    if !options[:items].nil?
      options[:items].each do |k,item|
        next if item.empty?
        item[:ajax] ||= 'get'
        item[:action] ||= item[:ajax]
        item[:oxremote] ||= 'false'
        item[:class] ||= ''
        item[:icon] ||= ''
        item[:url] ||= ''
        item[:browser] ||= ''
        item[:remote] ||= 'false'
        item[:method] ||= item[:ajax]
        str = []
        (item.keys - [:class,:icon]).each do |key|
          str << " data-%s='%s' " % [ key,item[key] ]
        end
        lst << "<li><a class='fab-button btn-floating %s' %s><i class='material-icons'>%s</i></a></li>" % [ item[:class], str.join, item[:icon] ]
      end
    end
    options[:list] ||= lst.join
    options
  end
end
