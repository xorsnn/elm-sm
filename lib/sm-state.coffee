StateMachine = require 'javascript-state-machine'

module.exports =
class SmState
  structure: {
    states: []
    transitions: []
    messages: []
    functions: {}
    specialFunctions: {
      update: null
    }
    module: ""
    imports: []
  }

  regExps: {
    newStructure: new RegExp("^(\\w)")
    functions: {re: new RegExp("^((?!(update|view|init|(\\w+View)))\\w+)\ :\ .+")}
    updateFunc: {re: new RegExp("^(update)\ :\ .+")}
  }

  currentBlock: null

  fsm: StateMachine.create({
    initial: 'waitingState',
    events: [
      {name: 'startReadingCommentMsg', from: 'waitingState', to: 'readingCommentState'},
      {name: 'stopReadingCommentMsg', from: 'readingCommentState', to: 'waitingState'},
      {name: 'startReadingFunctionMsg', from: 'waitingState', to: 'readingFunctionState'},
      {name: 'newRootStructureMsg', from: 'readingFunctionState', to: 'waitingState'},
      {name: 'startReadingUpdateFunctionMsg', from: 'waitingState', to: 'readingUpdateFunctionState'},
      {name: 'newRootStructureMsg', from: 'readingUpdateFunctionState', to: 'waitingState'},
    ]})

  constructor: ->
    return

  _parseUpateFunction: =>
    lines = @structure.specialFunctions.update.split('\n')
    lineCheckRegExp = new RegExp("^\ *(\\S)")
    caseStartRegExp = new RegExp("case\ +\\(.+\,.+\\)\ +of")
    transitionHeaderRegExp = new RegExp("\\(\ *(\\w+State).*\,\ *(\\w+Msg)\.*\\)\ *\-\>")
    # transitionFinRegExp = new RegExp("\\{\ *model\ *\\|\ *state\ *\=\ *(\\w+)\\}")
    transitionFinRegExp = new RegExp("\\{.+\\|.*state\\ *\\=\\ *(\\w+State).*\\}")

    getIndent = (line) ->
      match = line.match(lineCheckRegExp)
      return line.indexOf(match[0].trim())

    parseUpdate = (lines, indent = '', transitions = [], state = null) ->
      unless lines.length is 0
        line = lines.shift()
        if line.trim() isnt "" and line.trim().indexOf("--") is -1
          match = line.match(transitionHeaderRegExp)
          transitionFinMatch = line.match(transitionFinRegExp)

          if transitionFinMatch and state
            state.transition.to = transitionFinMatch[1]

          if match
            if state
              transitions.push(state.transition)
              state = null

            state = {
              indent: indent
              match: match
              transition: {
                from: match[1]
                msg: match[2]
                to: null
              }
            }

        return parseUpdate(lines, indent, transitions, state)
      else
        return transitions

    return parseUpdate(lines)

  parseLine: (line) =>

    # NOTE: handle multiline comments
    if @fsm.can('startReadingCommentMsg')
      if line.trim().indexOf('{-') is 0
        @fsm.startReadingCommentMsg()

    if @fsm.can('stopReadingCommentMsg')
      if line.trim().indexOf('-}') is 0
        @fsm.stopReadingCommentMsg()

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


    #NOTE: reading functions
    match = line.match(@regExps.functions.re)
    if match
      @currentBlock = {
        name: match[1]
        content: ''
      }
      @fsm.startReadingFunctionMsg()

    match = line.match(@regExps.updateFunc.re)
    if match
      @currentBlock = {
        name: match[1]
        content: ''
      }
      @fsm.startReadingUpdateFunctionMsg()

    switch @fsm.current
      when "readingFunctionState"
        @currentBlock.content += line + "\n"
      when "readingUpdateFunctionState"
        @currentBlock.content += line + "\n"

    return
