
SmState = require './sm-state'

{ CompositeDisposable } = require 'atom'

module.exports =
  subscriptions: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace'
      , 'elm-sm:toggle': => @toggle()
    return

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    return

  toggle: ->
    smState = new SmState()
    editor = atom.workspace.getActiveTextEditor()
    for row in [0..editor.getLineCount() ]
      lineText = editor.lineTextForBufferRow(row)
      smState.parseLine(lineText, row) if lineText
    commentText = smState.generateComment(smState._parseUpateFunction())
    editor.setCursorBufferPosition( [ 1, 0 ] )
    editor.scrollToCursorPosition()
    editor.insertText(commentText)
