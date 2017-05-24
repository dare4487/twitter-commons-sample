# this var holds whatever HTML has been parked
# to make room for a loader
#
class App.Shared
  constructor: (@el) ->
    # initialize some stuff
    # it will be re-instated with releaseLoader
    @loaded_html = ""
    @loaded_element = ""
    @currentForm = ""
    @defaultSpinner = '<div class="preloader-wrapper small active"> <div class="spinner-layer spinner-blue-only"> <div class="circle-clipper left"> <div class="circle"></div> </div><div class="gap-patch"> <div class="circle"></div> </div><div class="circle-clipper right"> <div class="circle"></div> </div> </div> </div>'
    @loading = false

  setCurrentForm: (f) =>
    @currentForm = f

  getCurrentForm: =>
    @currentForm

  callToast: (msg,time=3000,style="rounded") =>
     Materialize.toast(msg, time,style)


  #
  # openNewWindow
  #
  #
  openNewWindow: ($elem) =>
    props=''
    if $elem.data('props')
      try
        props = JSON.parse $elem.data('props')
      catch
        props = window.location.href.split("?")[1]
    url=$elem.data('url')
    if url.match /\?/
      props = "&" + props
    else
      props = "?" + props
    window.open (url + props)

  #
  # submitForm
  #
  #
  submitForm: ($elem) =>
    if $elem.data('selector')
      return $($elem.data('selector')).submit()
    $(document.body).find('form').first().submit()

  #
  # resetCheckBoxAndRadio
  # is a supportive funktion
  # to resetForm
  #
  resetCheckBoxAndRadio: (fld) =>
    if $(fld).data('original-value') && $(fld).data('original-value')==true
      fld.checked = true
    else
      fld.checked = false  if fld.checked

  #
  # resetForm
  # resets everything to <field data-original-value="" />
  # - except <field data-no-reset="true" />
  #
  resetForm: ($elem=null) =>
    if $elem && $elem.data('selector')
      frm = $elem.data('selector')
    else
      frm = $(document.body).find('form').first()[0]

    for fld in frm.elements
      do (fld) ->
        unless $(fld).data('no-reset')
          switch fld.type.toLowerCase()
            when 'text', 'password', 'textarea', 'hidden' then fld.value = $(fld).data('original-value') || ''
            when 'radio', 'checkbox'                      then App.shared.resetCheckBoxAndRadio(fld)
            when 'select-one', 'select-multi'             then fld.selectedIndex = $(fld).data('original-value') || -1

  getDownload: (xhr,data) =>
    # Check if a filename is existing on the response headers.
    filename = ""
    disposition = xhr.getResponseHeader("Content-Disposition")
    if disposition && disposition.indexOf("attachment") != -1
      filenameRegex = /filename[^;=\n]*=(([""]).*?\2|[^;\n]*)/
      matches = filenameRegex.exec(disposition)
      if matches != null && matches[1]
        filename = matches[1].replace(/[""]/g, "")
    #
    type = xhr.getResponseHeader("Content-Type")
    blob = new Blob([data], {type: type})
    #
    if typeof window.navigator.msSaveBlob != "undefined"
      # // IE workaround for "HTML7007: One or more blob URLs were revoked by closing the blob for which they were created. These URLs will no longer resolve as the data backing the URL has been freed.
      window.navigator.msSaveBlob(blob, filename)
    else
      URL = window.URL || window.webkitURL
      downloadUrl = URL.createObjectURL(blob)
      downloadUrl.oneTimeOnly = true
      #
      if filename
        # // Use HTML5 a[download] attribute to specify filename.
        a = document.createElement("a")
        # // Safari doesn"t support this yet.
        if typeof a.download == "undefined"
          window.location = downloadUrl
        else
          a.href = downloadUrl
          a.download = filename
          document.body.appendChild(a)
          a.click()
      else
        window.location = downloadUrl



  closeSweetAlert: ($elem=null) =>
    try
      unless $elem == undefined
        $elem.show()
      swal.close()
    catch error
      $('.sweet-overlay').hide()
      $('.sweet-alert').hide()


  # cloneObject will make a copy of an object - not a copy of the reference
  # to some object!
  #
  # var obj1= {bla:'blabla',foo:'foofoo',etc:'etc'};
  # var obj2= new cloneObject(obj1);
  #
  # 03-07-2015 (whd) not sure whether this method is OK!!!!
  # cp'ed from: http://scriptcult.com/subcategory_1/article_414-copy-or-clone-javascript-array-object
  #
  cloneObject: (source) =>
    for i in source
      if typeof source[i] == 'source'
        this[i] = new cloneObject source[i]
      else
        this[i] = source[i]


  #
  # printPost handles printing posts either way
  #
  printPost: (elem, loaded_element) =>
    switch elem.data('action')
      when 'new'    then @openNewWindow(elem)                       # data-action="new",    data-url="/endpoint", data-selector="#id.modal"
      when 'submit' then @submitForm(elem)                          # data-action="submit", data-selector="form"
      when 'ajax'   then @callAjax(elem, loaded_element)            # data-action="ajax",   data-url="/endpoint", data-selector="#id.modal", data-method="get", data-type="html", data-download="true"
      when 'get'    then window.location.href = elem.data('url')    # data-action="get",    data-url="/endpoint"
      else eval(elem.data('action'))                                # data-action="$(document.body).trigger({ type: 'app:modal:state:changed', state: {print_format: 'record' }})"


  #
  # callAjax
  # data-action="ajax",   data-url="/endpoint", data-selector="#id.modal", data-method="get", data-type="html"
  # data-action="ajax",   data-url="/endpoint", data-selector="download", data-method="get", data-type="html"
  # data: { action: "ajax", url: confinement_stock_items_url(format: 'js'), selector: "#edit_confinement.modal", method: "get", type: "html" }
  #
  callAjax: ($elem, loaded_element) =>
    return unless App.shared.spinWhileLoading( loaded_element )
    jqxhr = $.ajax
      url: $elem.data('url') || $elem.attr('href')
      type: $elem.data('method') || 'get'
      data: App.shared.dataArgumentOn($elem)
      dataType: $elem.data('type') || 'html'
    .done (data) =>
      console.log 'done'
      @spinWhileLoading()
      @setJqxhrData($elem,data)
    .fail (response,status) =>
      console.log 'fail'
      @spinWhileLoading()
      if jqxhr.state=='rejected'
        @reportError('Der er ingen forbindelse til serveren - prøv lidt senere!')
      else
        @setJqxhrData($elem,response.responseText)

  #
  # setJqxhrData
  # will try to massage the server response into it's proper place
  #
  setJqxhrData: ($elem,data) =>
    try
      if $elem.data('selector')
        if $elem.data('selector').match /^download$/i
          @getDownload(jqxhr,data)
        else
          $( $elem.data('selector') ).html(data)
          if $elem.data('selector').match /\.modal/
            $( $elem.data('selector') ).openModal()
      else
        $(document.body).append(data)

    catch error
      @reportError(error)


  #
  # spinWhileLoading
  # spinner to indicate something is going on
  #
  spinWhileLoading: (e=null,loader=null) =>
    return false if e && @isLoading()
    return @releaseLoader() if @isLoading()
    e = e.target if e instanceof Event || e instanceof jQuery.Event
    @setLoader( e,loader )


  #
  # set a loader - see http://materializecss.com/preloader.html
  # for examples
  #
  setLoader: (elem,html) =>
    try
      html ||= @defaultSpinner #'<div class="progress"><div class="indeterminate"></div></div>'
      @loaded_element = $(elem)
      @loaded_html = @loaded_element.html()
      @loading = true
      return @loaded_element.html(html)
    catch err
      console.log err

  #
  # isLoading
  # return @loading === true
  #
  isLoading: () =>
    @loading == true

  #
  # release the loader
  #
  releaseLoader: (elem=null) =>
    @loading=false
    elem ||= @loaded_element
    $(elem).html(@loaded_html)

  #
  # tellResponse will prepend a msg and optionally fade it out
  #
  tellResponse: (msg,anchor='.message_container',fade=15000,selector='.alert') =>
    $(anchor).prepend(msg)
    if fade>0
      @fadeItOut $(anchor).find(selector), 15000

  #
  # reportError
  # will show an error notification
  #
  reportError: (msg) =>
    @callToast msg, 4500, 'red lighten-3'


  #
  # fadeItOut will fade an element out with a preset or
  # supplied delay
  #
  fadeItOut: (e,delay=3500) =>
    $(e).delay( delay ).fadeOut( 1000 )

  #
  # dataArgumentOn constructs the data: argument on AJAX calls
  # from what ever data- attributes an element holds
  #
  # excemptions: data-id, data-remote, data-ajax, data-method, data-type and data-url
  #
  dataArgumentOn: (elem) =>
    $(elem).data()
    # try
    #
    #   swal( 'pageOnLoad', 'pageOnLoad blev kaldt!', 'success')
    #
    # catch error
    #   console.log 'ok - giving up'
    # console.log 'page loaded!'

  #
  # buildUrl will return current window.location.href with optional &args
  # but will keep ?q= part of string
  # argument: querystring part: &something=whatnot&other=else
  #
  buildUrl: (qs,match) =>
    m = match || /q=/
    loc = window.document.location
    searches = loc.search.split("&")
    search = (s for s in searches when s.match(m)) || ''
    url = loc.origin + loc.pathname + search.join("&")
    if url.match(/\?/)
    	url = url + qs
    else
    	url = url + '?' + qs



  #
  # check to see iff this browser supperts the File APIs
  #
  fileApiSupportCheck: () =>
    if (window.File && window.FileReader && window.FileList && window.Blob)
      # All the File APIs are supported.
      console.log 'file APIs supported '
    else
      document.getElementById('message_container').innerHTML = '<div class="alert fade in alert-warning"><a href="#!" class="warning close-notice btn-floating btn-small waves-effect waves-light" aria-hidden="true" type="button" data-dismiss="alert"><i class="material-icons">close</i></a>This browser does not support this application fully! Use latest Chrome - or advance cautiously!</div>';
