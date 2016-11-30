StateMachine = require 'javascript-state-machine'

module.exports =
class SmState
  structure: {
    states: []
    transitions: []
    messages: []
    functions: {}
    specialFunctions: []
    module: ""
    imports: []
  }

  regExps: {
    newStructure: new RegExp("^(\\w)")
    functions: {re: new RegExp("^((?!(update|view|init|(\\w+View)))\\w+)\ :\ .+"), id: '%1'}
  }

  currentBlock: null

  fsm: StateMachine.create({
    initial: 'waitingState',
    events: [
      {name: 'startReadingCommentMsg', from: 'waitingState', to: 'readingCommentState'},
      {name: 'stopReadingCommentMsg', from: 'readingCommentState', to: 'waitingState'},
      {name: 'startReadingFunctionMsg', from: 'waitingState', to: 'readingFunctionState'},
      {name: 'newRootStructureMsg', from: 'readingFunctionState', to: 'waitingState'},
    ]})

  constructor: ->
    return

  parseLine: (line) =>

    # NOTE: handle multiline comments
    if line.trim().indexOf('{-') is 0
      @fsm.startReadingCommentMsg()

    if line.trim().indexOf('-}') is 0
      @fsm.stopReadingCommentMsg()

    # NOTE: handle single line comments
    if line.trim().indexOf('--') is 0
      console.log 'single comment'

    # reset if new structure starting
    if @fsm.can('newRootStructureMsg')
      if line.match(@regExps.newStructure)
        if line.trim().indexOf(@currentBlock.name) isnt 0
          switch @fsm.current
            when "readingFunctionState"
              @structure.functions[@currentBlock.name] = @currentBlock.content
          console.log @structure
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


    switch @fsm.current
      when "readingFunctionState"
        @currentBlock.content += line + "\n"

    return