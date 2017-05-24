#
# App is the (only) global object
#
# reacts to 'app.something' events
#
window.App ||= { name: 'App', shared: null, cf: null, ps: null, _me: 0, page: null, sweet: null, resourceslist: null, resourceform: null, fab: null, currentPage: null }

App.currentForm = (val) ->
  @shared.setCurrentForm(val)

App.currentForm = ->
  @shared.getCurrentForm()

App.trigger = (event) ->
  $(App).trigger(event)

#
# signal App
App.init = ->

  @_me += 1

  if @_me < 2

    unless App.sweet
      App.sweet = new App.SweetAlert()

    unless App.resourceslist
      App.resourceslist = new App.ResourcesList($('form'))

    unless App.resourceform
      App.resourceform = new App.ResourceForm()

    unless App.fab
      App.fab = new App.fabDelete()

    unless @page
      @page = new App.Materialize()

    unless @shared
      @shared = new App.Shared()

    unless @ps
      @ps = new App.PageScrolling()

    #
    App.trigger('app:init')
    #
    # Try to keep users from double-clicking submit's
    #
    # document.addEventListener('DOMContentLoaded', disableMultipleSubmits, false);

    #
    # Prepare close-notice's for acting on clicks to remove div
    #
    $(document.body).off('click.close_notice')
    $(document.body).on 'click.close_notice', 'a.close-notice', App.closeNotice


#
# signal a pageload
App.pageload = ->
  App.trigger('app:pageload')

App.pageunload = ->
  App.trigger('app:pageunload')

#
# closeNotice
# will close the notice DIV
App.closeNotice = (e) ->
  App.shared.fadeItOut $(e.currentTarget).closest('.alert') #.remove()



#
# PageOnChange really just calls a pageload - as of now 19-06-15
# fixed elements like SELECT's, Materialized's elements, et al.
#
# @pageOnChange = () ->
#   console.log 'page changed '
#   pageOnLoad()
#
# call the App.pageload
$(document).on 'page:change', ->
  App.pageload()
#
# $(window).on 'page:unload', ->
#   alert 'fisk'
#   App.pageunload()
