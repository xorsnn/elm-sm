StateMachine = require 'javascript-state-machine'

module.exports =
class SmState

  regExps: {
    newStructure: new RegExp("^(\\w)")
    functions: new RegExp("^((?!(update|view|init|(\\w+View)))\\w+)\ :\ .+")
    updateFunc: new RegExp("^(update)\ :\ .+")
    moduleRegExp: new RegExp("^module\\ .+\\ exposing\\ .+")
    transitionDiagramHeaderRegExp: new RegExp("TRANSITION DIAGRAM")
  }

  # CONST
  BLOCK_TYPES: ['MULTILINE_COMMENT', 'SINGLE_LINE_COMMENT', 'UPDATE_FUNCTION']
  MULTILINE_COMMENT: 0
  SINGLE_LINE_COMMENT: 1
  UPDATE_FUNCTION: 2


  constructor: ->
    @structure = {
      states: []
      transitions: []
      messages: []
      functions: {}
      specialFunctions: {
        update: null
      }
      module: ""
      imports: []
      transitionTable: null
    }
    @currentBlock = null
    @fsm = StateMachine.create({
      initial: 'waitingState',
      events: [
        { name: 'startReadingCommentMsg', from: 'waitingState', to: 'readingCommentState' } ,
        { name: 'startReadingTransitionDiagramMsg', from: 'readingCommentState', to: 'readingTransitionDiagram' } ,
        { name: 'stopReadingTransitionDiagramMsg', from: 'readingTransitionDiagram', to: 'readingCommentState' } ,
        { name: 'stopReadingCommentMsg', from: 'readingCommentState', to: 'waitingState' } ,
        { name: 'startReadingFunctionMsg', from: 'waitingState', to: 'readingFunctionState' } ,
        { name: 'newRootStructureMsg', from: 'readingFunctionState', to: 'waitingState' } ,
        { name: 'startReadingUpdateFunctionMsg', from: 'waitingState', to: 'readingUpdateFunctionState' } ,
        { name: 'newRootStructureMsg', from: 'readingUpdateFunctionState', to: 'waitingState' } ,
        { name: 'readModuleString', from: 'waitingState', to: 'readingModuleString' } ,
      ] } )

    return

  _parseUpateFunction: =>
    lines = @structure.specialFunctions.update.split('\n')
    lineCheckRegExp = new RegExp("^\ *(\\S)")
    caseStartRegExp = new RegExp("case\ +\\(.+\,.+\\)\ +of")
    transitionHeaderRegExp = new RegExp("\\(\ *(\\w+State).*\,\ *([A-Z]\\w+)(\\ +\\(\\ *[Ok|Err].*\\ *\\))?\.*\\)\ *\-\>")
    transitionFinRegExp = new RegExp("\\{.+\\|.*state\\ *\\=\\ *(\\w+State).*\\}")

    getIndent = (line) ->
      match = line.match(lineCheckRegExp)
      return line.indexOf(match[0].trim())

    parseUpdate = (lines, indent = '', transitions = [], state = null) ->
      unless lines.length is 0
        line = lines.shift()
        if line.trim() isnt "" and line.trim().indexOf("--") is - 1
          match = line.match(transitionHeaderRegExp)
          transitionFinMatch = line.match(transitionFinRegExp)

          if transitionFinMatch and state
            state.transition.to = transitionFinMatch[1]

          if match
            if state
              transitions.push(state.transition)
              state = null

            msg = match[2]
            if match[3]
              if match[3].indexOf('Ok') isnt -1
                msg += ' Ok'
              if match[3].indexOf('Err') isnt -1
                msg += ' Err'

            state = {
              indent: indent
              match: match
              transition: {
                from: match[1]
                msg: msg
                to: null
              }
            }

        return parseUpdate(lines, indent, transitions, state)
      else
        return transitions

    return parseUpdate(lines)

  generateComment: (transitions, comment = true) ->
    res = ''
    res += '{-\n' if comment
    res += 'TRANSITION DIAGRAM\n'
    res += '{\n'
    for transition in transitions
      res += '[ ' + transition.from + ', ' + transition.msg + ', ' + transition.to + ' ]\n'
    res += '}\n'
    res += '-}\n' if comment
    return res

  parseLine: (line, row) =>

    # NOTE: handle multiline comments
    if @fsm.can('startReadingCommentMsg')
      if line.trim().indexOf('{-') is 0
        @currentBlock = {
          blockType: @MULTILINE_COMMENT
          startRow: row
        }
        @fsm.startReadingCommentMsg()

    if @fsm.can('stopReadingCommentMsg')
      if line.trim().indexOf('-}') is 0
        @currentBlock.content += line + '\n'
        @currentBlock.lastRow = row
        @currentBlock = null
        @fsm.stopReadingCommentMsg()

    if @fsm.can('startReadingTransitionDiagramMsg')
      if line.match(@regExps.transitionDiagramHeaderRegExp)
        @structure.transitionTable = {
          startRow: row
        }
        @fsm.startReadingTransitionDiagramMsg()

    if @fsm.can('stopReadingTransitionDiagramMsg')
      if line.indexOf('}') isnt -1
        @structure.transitionTable.content += line + '\n'
        @structure.transitionTable.lastRow = row
        @fsm.stopReadingTransitionDiagramMsg()

    # NOTE: handle single line comments
    if line.trim().indexOf('--') is 0
      console.log 'single comment'

    # reset if new structure starting
    if @fsm.can('newRootStructureMsg')
      if line.match(@regExps.newStructure)
        if @currentBlock
          if line.trim().indexOf(@currentBlock.name) isnt 0
            switch @fsm.current
              when "readingFunctionState"
                @structure.functions[@currentBlock.name] = @currentBlock.content
              when "readingUpdateFunctionState"
                @structure.specialFunctions.update = @currentBlock.content
            @currentBlock = null
            @fsm.newRootStructureMsg()


    # NOTE: reading functions
    match = line.match(@regExps.functions)
    if match
      @currentBlock = {
        name: match[1]
        content: ''
      }
      @fsm.startReadingFunctionMsg()

    match = line.match(@regExps.updateFunc)
    if match
      @currentBlock = {
        blockType: @UPDATE_FUNCTION
        name: match[1]
        content: ''
      }
      @fsm.startReadingUpdateFunctionMsg()

    match = line.match(@regExps.moduleRegExp)

    if match
      console.log ">>>>>>>>>>>>>>>>>>>>>.."
      console.log line

    switch @fsm.current
      when "readingFunctionState"
        @currentBlock.content += line + '\n'
      when "readingUpdateFunctionState"
        @currentBlock.content += line + '\n'
      when "readingCommentState"
        @currentBlock.content += line + '\n'
      when "readingTransitionDiagram"
        # if line.indexOf('{') isnt -1
        #   @structure.transitionTable.startRow = row
        @structure.transitionTable.content += line + '\n'
        @currentBlock.content += line + '\n'

    return
