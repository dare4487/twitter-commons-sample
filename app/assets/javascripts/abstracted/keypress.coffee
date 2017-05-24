#
# start looking on App.trigger 'ctrlf'
# looking for search-key - CTRL-F
#
$(App).on 'ctrlf', ->

  #
  # watch out for search key - CTRL-F
  $(document).keypress (e) =>
    if (e.which==6)
      checkWebkitandIE=1
    else
      checkWebkitandIE=0

    if (e.which==102 && e.ctrlKey)
      checkMoz=1
    else
      checkMoz=0

    if (checkWebkitandIE || checkMoz)
      if $('input.search-list')
        $('input.search-list').focus()
    # console.log e
