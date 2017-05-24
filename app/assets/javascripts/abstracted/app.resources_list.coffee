class App.ResourcesList

  constructor: (@el) ->
    # initialize some stuff
    @searchForm = @el[0]

  #
  # searchPost handles ordering search on index actions
  #
  orderSearch: (url,query) =>
    loader = '<div class="preloader-wrapper small active"> <div class="spinner-layer spinner-blue-only"> <div class="circle-clipper left"> <div class="circle"></div> </div><div class="gap-patch"> <div class="circle"></div> </div><div class="circle-clipper right"> <div class="circle"></div> </div> </div> </div>'
    loaded_element = $('.fixed-action-btn')
    App.shared.setLoader( loaded_element,loader )
    window.location.href= url + '?q=' + encodeURIComponent(query)

  #
  # handleLinkedUrls handles other urls referred by an A tag
  #
  handleLinkedUrls: (e) =>
    e.preventDefault()
    e.stopPropagation()
    loaded_element = $(e.currentTarget)
    App.shared.spinWhileLoading( loaded_element )
    url = '&' + $(e.currentTarget).data('url').split('?')[1]
    window.location.href = App.shared.buildUrl(url,/q=/)

  #
  # handleColumnSort will
  #
  handleColumnSort: (e) =>
    e.preventDefault()
    e.stopPropagation()
    dir = $(e.currentTarget).data('direction') || 'asc'
    fld = $(e.currentTarget).data('field') || 'id'
    srt = '&s=' + fld + '&d=' + dir
    window.location.href = App.shared.buildUrl(srt,/q=/)

		# jqxhr = $.ajax
		# 	url: url,
		# 	type: 'GET',
		# 	dataType: 'html'
		# jqxhr.done (data, textStatus, jqXHR) ->
		# 	$('tbody.page.resources_list').html(data)
		# jqxhr.fail (data, textStatus, errorThrown) ->
		# 	$('#message_container').html(data.responseText)



  #
  # handleAttachLinks
  # allows for attaching/detaching resources from their parents - like: /admin/users/2/printers/3/attach.js
  #
  handleAttachLinks: (e) =>
    e.preventDefault()
    e.stopPropagation()

    $elem = $(e.currentTarget)
    request = $.ajax
      url: $elem.attr('href'),
      type: "get",
      dataType: 'html'
    .done (data) =>
      $( $elem[0].parentElement).html(data)

    .error (data) =>
      swal("Oops", "We couldn't connect to the server!", "error")
    return false

  #
  # handleActivateLinks
  # allows for activating/deactivating resources - like: /admin/users/2/activate
  #
  handleActivateLinks: (e) =>
    e.preventDefault()
    e.stopPropagation()

    $elem = $(e.currentTarget)
    request = $.ajax
      url: $elem.attr('href'),
      type: "get",
      dataType: 'html'
    .done (data) =>
      $( $elem[0].parentElement).html(data)

    .error (data) =>
      swal("Oops", "We couldn't connect to the server!", "error")
    return false


  #
  # handlePreferredLinks
  # allows for preferring/deferring resources - like: /admin/printers/2/prefer & /admin/printers/2/defer
  #
  handlePreferredLinks: (e) =>
    e.preventDefault()
    e.stopPropagation()

    $elem = $(e.currentTarget)
    # are we preferring?
    prefer = $elem.attr('href').match /prefer/
    request = $.ajax
      url: $elem.attr('href'),
      type: "get",
      dataType: 'html'
    .done (data) =>
      if prefer
        sel='a.preferred'
        if $elem.attr('ref')!=undefined
          sel='a.preferred[ref="x"]'.replace /x/, $elem.attr('ref')
        $(sel).each (k,e) =>
          $e=$(e)
          if $e!=$elem
            url=$e.attr('href').replace 'defer', 'prefer'
            $e.attr 'href', url
            $e.html '<i class="deferred material-icons grey-text">bookmark_border</i>'

      $elem.html(data)
      # if prefer
      #   sel='a.preferred'
      #   if $elem.attr('ref')!=undefined
      #     sel='a.preferred[ref="x"]'.replace /x/, $elem.attr('ref')
      #
      #   $(sel).each (k,e) =>
      #     $e = $(e)
      #     if $e != $elem
      #       console.log $e
      #       $e.attr('href').replace 'defer', 'prefer'
      #       $e.html '<i class="deferred material-icons grey-text">bookmark_border</i>'
      #
      #   $elem.html '<i class="preferred material-icons green-text">bookmark</i>'


      # # here we have to write all the existing preferred ones
      # $.when $(sel).each (k,e) =>
      #   $e = $(e)
      #   $e.attr('href').replace 'defer', 'prefer'
      #   $e.html '<i class="deferred material-icons grey-text">bookmark_border</i>'
      #   # $( $elem[0].parentElement).html(data)
      # .then $elem.html '<i class="preferred material-icons green-text">bookmark</i>'


    .error (data) =>
      swal("Oops", "We couldn't connect to the server!", "error")
    return false

  #
  # handlePrintLinks
  # initializes the tags classed with '.print_post_link' to print a post
  #
  handlePrintLinks: (e) =>
    e.preventDefault()
    e.stopPropagation()

    elem = $(e.currentTarget)
    loaded_element = elem.closest('.loader_container')
    App.shared.printPost( elem, loaded_element )

  #
  # starting a search - and making some noise about it!
  #
  searchKey: (e) =>
    if e.keyCode == 13
      e.preventDefault()
      e.stopPropagation()
      $elem = $('input.search-list')
      @orderSearch(@searchForm.action, $elem.val())

  #
  # starting a search - and making some noise about it!
  #
  searchClick: (e) =>
    e.preventDefault()
    e.stopPropagation()
    $elem = $('input.search-list')
    @orderSearch(@searchForm.action, $elem.val())


  prepare: =>

    @searchForm = $('#list-search-form')[0]

    try
      $(document.body).off('click.print')
      $(document.body).off('keydown.search')
      $(document.body).off('click.search')

      $(document.body).on 'click.print', 'a.print_post_link, a.print_item', @handlePrintLinks
      $(document.body).on 'keydown.search', 'input.search-list', @searchKey
      $(document.body).on 'click.search', 'form a.search-list[type="submit"]', @searchClick

      #
      # If this page has a resources_list
      #
      $('table.resources_table').map (k,t) =>
        $(document.body).off('click.attach')
        $(document.body).off('click.activate')
        $(document.body).off('click.prefer')
        $(document.body).off('click.sort_on_column')
        $(document.body).off('click.linked_urls')
        $(document.body).on 'click.attach', 'a.attached, a.detached', @handleAttachLinks
        $(document.body).on 'click.activate', 'a.activated, a.deactivated', @handleActivateLinks
        $(document.body).on 'click.prefer', 'a.preferred, a.deferred', @handlePreferredLinks
        $(document.body).on 'click.sort_on_column', 'th[role="sort"]', @handleColumnSort
        $(document.body).on 'click.linked_urls', 'a.linked_url', @handleLinkedUrls

    catch error
      alert 'App.ResourcesList did not prepare!'
      console.log error
