$ = require 'jquery'
SmView = require './sm-view'
Parser = require './sm-parser'

path = require 'path'

{CompositeDisposable} = require 'atom'

module.exports =
  smView: null
  parser: null
  subscriptions: null

  config:
    collapsedGroups:
      title: 'Groups that are initially collapsed'
      description: 'List groups separated by comma (e.g. Variable) '
      type: 'string'
      default: 'Variable'
    ignoredGroups:
      title: 'Groups that are ignored'
      description: 'These groups will not be displayed at all'
      type: 'string'
      default: ''
    topGroups:
      title: 'Groups at top'
      description: 'Groups that are displayed at the top, irrespective ofrting'
      type: 'string'
      default: 'Bookmarks, Todo'
    sort:
      title: 'Sort Alphabetically'
      type: 'boolean'
      default: true
    noDups:
      title: 'No Duplicates'
      type: 'boolean'
      default: true


  enabled: false
  activate: (state) ->
    # TODO: check @enabled flag later
    # @enabled = not (state.enabled is false)
    # @enabled = not @enabled

    @subscriptions = new CompositeDisposable

    settings = atom.config.getAll('elm-sm')[0].value
    console.log '**********************************'
    console.log settings
    console.log '**********************************'

    @parser = new Parser()
    @smView = new SmView(state, settings, @parser)

    @subscriptions.add atom.config.onDidChange 'elm-sm', (event) =>
      settings = event.newValue
      for key, value in settings
        if key.indexOf('Groups') > 0
          settings[key] = value.split(',')
      @smView.changeSettings(settings)

    @subscriptions.add atom.commands.add 'atom-workspace'
      , 'elm-sm:toggle': => @toggle()

    @subscriptions.add atom.workspace.onDidStopChangingActivePaneItem (paneItem) =>
      @_updatePanel(paneItem)

    @subscriptions.add atom.workspace.onWillDestroyPaneItem (event) =>
      if event.item.ziOnEditorSave
        @smView.saveFileState(event.item.getPath())

  _updatePanel: (paneItem) ->
    editor = atom.workspace.getActiveTextEditor()

    return @smView.hide() unless editor
    return if editor isnt paneItem

    editorFile = editor.getPath() # undefined for new file
    @smView.setFile(editorFile)
    # Panel also needs to be updated when text saved
    return unless editor and editor.onDidSave
    if not editor.ziOnEditorSave
      editor.ziOnEditorSave = editor.onDidSave (event) =>
        return unless @enabled
        # With autosave, this gets called before onClick.
        # We want click to be handled first
        # setImmediate didn't work.
        setTimeout =>
          editorFile = editor.getPath()
          @smView.updateFile(editorFile) if editorFile
        , 200
      @subscriptions.add editor.ziOnEditorSave

      @subscriptions.add editor.onDidDestroy =>
        @smView.closeFile(editorFile)


  deactivate: ->
    @smView.destroy()
    @parser.destroy()
    @subscriptions.dispose()
    @smView = null


  serialize: ->
    enabled: @enabled
    fileStates: @smView.getState()


  toggle: ->
    @enabled = not @enabled
    @smView.enable(@enabled)
    editor = atom.workspace.getActiveTextEditor()
    @_updatePanel(editor) if @enabled and editor
