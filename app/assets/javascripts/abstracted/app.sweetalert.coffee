class App.SweetAlert
  constructor: (@el) ->
    # initialize some stuff


  #
  # initializeSweetAlert
  # initializes the sweetalert prompt
  #
  initializeSweetAlert: () =>
    try
      # console.log 'sweet alert initializing...'
      # sweetHTML = '<div class="sweet-overlay" tabIndex="-1"></div><div class="sweet-alert" tabIndex="-1"><div class="icon error"><span class="x-mark"><span class="line left"></span><span class="line right"></span></span></div><div class="icon warning"> <span class="body"></span> <span class="dot"></span> </div> <div class="icon info"></div> <div class="icon success"> <span class="line tip"></span> <span class="line long"></span> <div class="placeholder"></div> <div class="fix"></div> </div> <div class="icon custom"></div> <h2>Title</h2><p>Text</p><button class="cancel" tabIndex="2">Cancel</button><button class="confirm" tabIndex="1">OK</button></div>'
      # sweetWrap = document.createElement('div')
      # sweetWrap.innerHTML = sweetHTML
      # $(document.body).append(sweetWrap)
      # console.log 'sweetalert initialized!'
    catch error
      console.log 'sweetalert says: ' + error


  prepare: =>

    try
      if ($('.sweet-alert').length<1)
        @initializeSweetAlert()
      if ($('.sweet-alert').length>0)
        console.log 'sweet-alert initialized correctly!' #swal( 'pageOnLoad', 'pageOnLoad blev kaldt!', 'success')

    catch error
      alert 'App.Materialize did not prepare!'
      console.log error
