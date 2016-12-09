
SmState = require './sm-state'

{ CompositeDisposable } = require 'atom'

module.exports =
  subscriptions: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace'
      , 'elm-sm:generateDigaram': => @generateDigaram()
    return

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    return

  generateDigaram: ->
    smState = new SmState()
    editor = atom.workspace.getActiveTextEditor()
    for row in [ 0..editor.getLineCount() ]
      lineText = editor.lineTextForBufferRow(row)
      smState.parseLine(lineText, row) if lineText

    currentTransitionTable = smState.structure.transitionTable
    if currentTransitionTable
      editor.getLastSelection().setBufferRange [
        [currentTransitionTable.startRow, 0]
        [currentTransitionTable.lastRow, editor.lineTextForBufferRow(currentTransitionTable.lastRow).length]
      ]
      commentText = smState.generateComment(smState._parseUpateFunction(), false)
      editor.insertText(commentText)
    else
      commentText = smState.generateComment(smState._parseUpateFunction())
      editor.setCursorBufferPosition( [ 1, 0 ] )
      editor.scrollToCursorPosition()
      editor.insertText(commentText)
