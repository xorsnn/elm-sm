$ = require 'jquery'

module.exports =
class ResizableWidthView
  viewContainer: null
  mainView: null
  handle: null
  resizerPos: null


  constructor: (resizerPos = 'left') ->
    @resizerPos = resizerPos
    if resizerPos is 'left'
      fragment = """
                 <div class="sm-width-resizer"></div>
                 <div class="sm-mainview"></div>
                 """
    else
      fragment = """
                 <div class="sm-mainview"></div>
                 <div class="sm-width-resizer"></div>
                 """

    html = """
           <div class="sm-resizable">
           #{fragment}
           </div>
           """
    @viewContainer = $(html)
    @mainView = @viewContainer.find('.sm-mainview')
    @handle = @viewContainer.find('.sm-width-resizer')
    @handleEvents()


  handleEvents: ->
    @handle.on 'dblclick', =>
      @resizeToFitContent()

    @handle.on 'mousedown', (e) => @resizeStarted(e)


  resizeStarted: =>
    $(document).on('mousemove', @resizeView)
    $(document).on('mouseup', @resizeStopped)


  resizeStopped: =>
    $(document).off('mousemove', @resizeView)
    $(document).off('mouseup', @resizeStopped)


  resizeView: ({pageX, which}) =>
    return @resizeStopped() unless which is 1

    if @resizerPos is 'left'
      deltaX = @viewContainer.offset().left - pageX
      width = @viewContainer.width() + deltaX
    else
      width = pageX - @viewContainer.offset().left
    @viewContainer.width(width)


  resizeToFitContent: ->
    @viewContainer.width(@mainView.width() + 20)
