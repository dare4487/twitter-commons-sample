class App.ResourceForm
  constructor: (@el) ->
    # initialize some stuff

  #
  # make sure fields with values do not have their labels obscuring your view
  #
  setLabels: (selector) ->
    $(selector).each () ->
      try
        fld = '#'+$(this).attr('for')
        $(this).addClass('active') unless $(fld)[0].value.nil?
      catch
        #console.log this

  #
  # prepare the form - a data: {form_type: record }
  # kind of form that is
  prepare: ->

    try


      #
      # make labels on fields with content move out of the way
      #
      @setLabels('.input-field label')

      #
      # Initialize INPUT TYPE='DATE'
      #
      #   %input.datepicker{ type:"date" }
      #
      $('.datepicker').pickadate
        selectMonths: true, # Creates a dropdown to control month
        selectYears: 15     # Creates a dropdown of 15 years to control year

    catch error
      alert 'App.ResourceForm did not prepare!'
      console.log error
