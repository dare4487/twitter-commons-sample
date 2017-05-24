class App.fabDelete

  constructor: (@el) ->
    # initialize some stuff

  #
  # deletePost handles deleting records
  #
  # dependencies:
  #   sweetalert
  #
  #   data-url="", data-id="" - eg.
  deletePost: ($elem) =>
    try
      url = $elem.data('url') + "/" + $elem.data('id') + ".js"
      $remove = $($elem.data('remove'))
      request = $.ajax
        url: url,
        type: "delete",
        dataType: 'html'
      .done (data) =>
        if $remove
          $remove.hide()
        App.shared.closeSweetAlert($elem)
        if (window.location.href).endsWith($elem.data('url')+"/"+$elem.data('id'))
          window.location = $elem.data('url')
        #swal("Deleted!", "Your file was successfully deleted!", "success")
      .fail (data) =>
        $('#message_container').html(data.responseText)
        $elem.show()
        swal("Oops", "We couldn't connect to the server!", "error")

    catch error
      swal "Hmmm", "Most unexpected! \n#{error}", "error"


  #
  # handleFABLinks
  # handles click on the fab_button
  #
  # buttons will have 5 courses of action
  #
  # 1) call a new window
  # 2) eval string - like "$(selector).openModal()"
  # 3) make a AJAX call to get some resource to present either in the document.body, a DOMnode, or in a modal
  # 4) POST the first form on the current document.body
  # 5) GET the data-url
  #
  # hence the button will have a number of attribs
  #
  #   data-action                     [ "new" | "ajax" | "submit" | "get" | "string to eval" ]
  #   data-url                        "/endpoint"
  #   data-selector                   [ "DOM node to operate on - ie submit, fill, etc" | "download" ]
  #   data-props                      [ 'true' | '[ 1, "two", { "three": "3" }]' ]
  #
  handleFABLinks: (e) =>
    e.preventDefault()
    e.stopPropagation()

    elem = $(e.currentTarget)
    loaded_element = elem.closest('.fixed-action-btn')

    switch elem.data('action')
      when undefined  then alert 'Fejl!\n Kontakt ALCO på 9791 1470\n (fejlen er: handleFABLinks ikke sat)'
      when 'new'      then App.shared.openNewWindow(elem)                    # data-action="new",    data-url="/endpoint", data-selector="#id.modal"
      when 'reset'    then App.shared.resetForm(elem)                        # data-action="reset",  data-selector="form"
      when 'submit'   then App.shared.submitForm(elem)                       # data-action="submit", data-selector="form"
      when 'post'     then App.shared.submitForm(elem)                       # data-action="post",   data-selector="form"
      when 'delete'   then @handleDeleteLinks(e)                             # data-action="delete", data-selector="form", data-id="id", data-url="url"
      when 'ajax'     then App.shared.callAjax(elem,loaded_element)          # data-action="ajax",   data-url="/endpoint", data-selector="#id.modal", data-method="get", data-type="html"
      when 'get'      then window.location.href = elem.data('url')           # data-action="get",    data-url="/endpoint"
      else eval(elem.data('action'))                                         # data-action="$(document.body).trigger({ type: 'app:modal:state:changed', state: {print_format: 'record' }})"


  #
  # handleDeleteLinks
  # initializes the tags classed with '.delete_link' to verify deleting an issue
  #
  # if the calling elem has a data-what-to-delete attrib - this will be shown
  #
  handleDeleteLinks: (e) =>
    e.preventDefault()
    e.stopPropagation()
    $elem = $(e.currentTarget)
    title = $elem.data('delete-title') || "Are you sure?"
    prompt = $elem.data('delete-prompt') || "Are you sure that you want to delete this?"
    confirm = $elem.data('delete-confirm') || "Yes, delete it!"
    $elem.hide()

    $('.sweet-overlay').show()
    swal
      title: title,
      text: prompt,
      type: "warning",
      animation: "slide-from-bottom",
      showLoaderOnConfirm: true,
      showCancelButton: true,
      closeOnConfirm: false,
      confirmButtonText: confirm,
      confirmButtonColor: "#ec6c62",
      (confirmed) =>
        if !confirmed
          App.shared.closeSweetAlert($elem)
        else
          @deletePost($elem)
    return false


  prepare: =>

    try

      $(document.body).off('click.delete')
      $(document.body).off('click.fab')

      #
      # Prepare delete_link's for acting on clicks to delete posts
      #
      $(document.body).on 'click.delete', 'a.delete_link, a.delete_item', @handleDeleteLinks

      #
      # Add event on the FAB (fixed action button)
      #
      $(document.body).on 'click.fab', 'a.fab-button', @handleFABLinks

    catch error
      alert 'Fejl!\nLuk din browser og start igen - hvis fejlen stadig opstår, ring så til ALCO på tlf 9791 1470\nFejl: App.fabDelete did not prepare!'
      console.log error
