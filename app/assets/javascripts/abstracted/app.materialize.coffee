class App.Materialize
  constructor: (@el) ->
    # initialize some stuff

  prepare: =>

    try
      #
      # Initialize the 'hamburger'
      #
      $(".button-collapse").sideNav();

      #
      # Initialize collapsible (uncomment the line below if you use the dropdown variation)
      #
      $('.collapsible').collapsible
        accordion : true                  # A setting that changes the collapsible behavior to expandable instead of the default accordion style

      #
      # make drop-downs react nicely
      #
      $(".dropdown-button").dropdown()

      #
      # watch out for tooltipped

      #
      $('.tooltipped').tooltip({delay: 50})

      #
      # prepare for tabbed display of tabbed UL's
      #
      $('ul.tabs').tabs()
      $('.materialboxed').materialbox()

      #
      # Initialize SELECT's
      #
      $('select').each () ->
        # remove span.caret's from previous 'runs' - however that happens
        $(this).parent().parent().find('span.caret').remove()
        $(this).material_select()

    catch error
      alert 'App.Materialize did not prepare!'
      console.log error
