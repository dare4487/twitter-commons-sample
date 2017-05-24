
#
# standard triggers - and actions
#
$(App).on 'app:modal:open', ->
  #
  # mount React Components laying dormant in a modal
  window.ReactRailsUJS.mountComponents()
  App.trigger('app:pageload')

$(App).on 'app:pageload', ->
  App.page.prepare()
  App.sweet.prepare()
  if $('table.resources_table')
    App.resourceslist.prepare()
    App.ps.scrollTable('table.resources_table')
  App.resourceform.prepare()
  App.fab.prepare()

# $(App).on 'app:pageunload', ->
#   if App.ps && App.ps.scrollTimeout
#     clearTimeout App.ps.scrollTimeout
