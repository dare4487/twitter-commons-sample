class App.PageScrolling

  constructor: () ->
    # initialize some stuff
    @table=null
    @loadingPage = false
    # currentPage = 0
    # totalPages = 0
    @navPaginator = ''
    @lastPage = 0
    @nextPage = 0
    @pageUrl = ''
    @contxt = null
    @scrollTimeout = false
    @_me = 0

  evalPageNumber: (elem) =>
    if elem
      try
        pn = elem[0].href
          .split('?')[1]
          .split('&')
          .filter (el,i,array) ->
            if el.match /^page/
              return el
          .join('')
          .split('=')[1]
        parseInt(pn)
      catch error
        pn = 0

  #
  # setVariables prepares for a great scrolling experience
  #
  setVariables: (elem) =>
    return if $('nav.pagination').size() < 1
    @navPaginator = $('nav.pagination')
    try
      @pageUrl = @navPaginator.find('a[rel=next]')[0].href.replace( '?', '.js?scrolling=true&')
      @lastPage = @evalPageNumber @navPaginator.find('span.last a')
      @nextPage = @evalPageNumber @navPaginator.find('a[rel=next]')
      @contxt = $(elem)
      if @nextPage > 1
        @nextPage = 1
      console.log 'did setVariables'
      true

    catch error
      console.log error
      return false

  #
  # setPaginationHandler prepares to handle all clicks on
  # the nav.pagination links
  #
  # setPaginationHandler: () =>
  #   $(document.body).on 'click.pagination', '.first > a, .previous > a, .page > a, .next > a, .last > a', (e) =>
  #     @paginate(e)
  #
  # paginate: (e) =>
  #   e.preventDefault()
  #   e.stopPropagation()
  #   @nextPage = e.currentTarget.href.match(/page=(\d*)&/)[1]
  #   wurl = window.location.href.replace /#!$/, ''
  #   if !@pageUrl.split("?")[0].split(".js")[0].match wurl.split("?")[0]
  #     clearTimeout( @scrollTimeout )
  #     return false
  #   clearTimeout( @scrollTimeout )
  #   @loadNextPage @pageUrl.replace( /page=\d*&/, 'page=' + @nextPage + '&'), true


  #
  # closeToBottom checks to see if you're close to the bottom of the screen
  #
  closeToBottom: () =>
    return false if @loadingPage
    return false if @navPaginator.size() == 0
    return ($(window).scrollTop() - parseInt($(document).height()) + parseInt($(window).height())) > -200

  findNextPageToLoad: () =>
    @nextPage += 1
    if @nextPage > @lastPage
      clearTimeout( @scrollTimeout )
      return false
    wurl = window.location.href.replace /#!$/, ''
    if !@pageUrl.split("?")[0].split(".js")[0].match wurl.split("?")[0]
      clearTimeout( @scrollTimeout )
      return false
    @pageUrl
      .replace /page=\d*&/, 'page=' + @nextPage + '&'


  loadNextPage: (url,replace=false) =>
    # url = @findNextPageToLoad()
    if url
      console.log 'getting ready to load another page'
      return unless App.shared.spinWhileLoading '.fixed-action-btn', '<div class="preloader-wrapper small active"> <div class="spinner-layer spinner-blue-only"> <div class="circle-clipper left"> <div class="circle"></div> </div><div class="gap-patch"> <div class="circle"></div> </div><div class="circle-clipper right"> <div class="circle"></div> </div> </div> </div>'
      jqxhr = $.ajax
        url: url
        type: 'GET'
        dataType: 'html'
      .done (data) =>
        if replace
          @contxt.find('tbody').html(data)
        else
          @contxt.find('tbody').append(data)
        App.trigger('app:pageload')
        App.shared.spinWhileLoading()
      .fail (data) =>
        @loadingPage = false
        console.log 'err'
  #
  # scroll a list - behind the scenes calling in extra pages of content
  #
  scrollTable: (elem) =>
    console.log elem
    return if $(elem)[0] == undefined || App.currentPage == $(elem)[0].id
    App.currentPage = $(elem)[0].id
    return unless @setVariables(elem)
    if @lastPage > @nextPage && @nextPage < 3
      App.shared.callToast 'Der er mere end én side resultater - scroll ned for at se flere!'

    # pagination is hidden as of 8/3/2016
    # @setPaginationHandler()
    @table=elem
    if @nextPage > 0
      scrollHandler = () =>
        clearTimeout( @scrollTimeout )
        if @closeToBottom()
          $.when @loadNextPage(@findNextPageToLoad())
          .then @scrollTimeout = setTimeout( scrollHandler, 250)
          .then @navPaginator.hide()
        else
          setTimeout( scrollHandler, 250)

      @scrollTimeout = setTimeout( scrollHandler, 250)
