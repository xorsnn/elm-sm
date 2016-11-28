
module.exports =
class SmGenerator
  states: []
  actions: []
  transitions: []
  lines: []
  # STATES
  reading: false

  parseLine: (line) =>
    unless @reading
      ind = line.indexOf(">")
    if @reading
      ind = line.indexOf("<")

    if ind >= 0
      @reading = not @reading

    if @reading
      if (line isnt ">") and (line isnt "-}")
        @lines.push(line)

    return

  _addTransition: (line) =>
    transition = line.replace("[", "").replace("]", "").split(',')
    @transitions.push({
      from: transition[0].trim()
      to: transition[2].trim()
      event: transition[1].trim()
    })
    if transition[0].trim() not in @states
      @states.push(transition[0].trim())
    if transition[2].trim() not in @states
      @states.push(transition[2].trim())
    if transition[1].trim() not in @actions
      @actions.push(transition[1].trim())
    return

  _transitionToStr: (tr, indentation = "") ->
    res = ""
    res += indentation + "( " + tr.from + "," + tr.event + " ) ->\n"
    res += indentation + "  { model | state = " + tr.to + " } ! []\n"
    return res

  _generateStatesStr: =>
    res = "type State\n"
    res += "  = " + @states[0] + "\n"
    for i in [1...@states.length]
      res += "  | " + @states[i] + "\n"
    return res

  _generateActionsStr: =>
    res = "type Msg\n"
    res += "  = " + @actions[0] + "\n"
    for i in [1...@actions.length]
      res += "  | " + @actions[i] + "\n"
    return res

  _generateViewStr: =>
    indent = "  "
    resStr = ""
    resStr += "view : Model -> Html Msg\n"
    resStr += "view model =\n"
    resStr += indent + "case model.state of\n"
    for state in @states
      resStr += indent + state + " ->\n"
      resStr += indent + "    " + "div [] [text \"" + state + "\"]\n"
    return resStr

  _generateModelTypeStr: ->
    indent = "  "
    resStr = ""
    resStr += "type alias Model =\n"
    resStr += indent + "{ state : State}\n"
    return resStr

  _generateModelInplStr: =>
    indent = "  "
    resStr = ""
    resStr += "init : ( Model, Cmd Msg )\n"
    resStr += "init =\n"
    resStr += indent + "let\n"
    resStr += indent + indent + "model =\n"
    resStr += indent + indent + indent + "{state=" + @states[0]+ "}\n"
    resStr += indent + "in\n"
    resStr += indent + indent + "model ! []\n"
    return resStr

  _generateMainStr: ->
    res = "subscriptions : Model -> Sub Msg\n"
    res += "subscriptions model =\n"
    res += "  Sub.batch []\n"
    res += "main : Program Never\n"
    res += "main =\n"
    res += "  Html.App.program\n"
    res += "    { init = init\n"
    res += "    , view = view\n"
    res += "    , update = update\n"
    res += "    , subscriptions = subscriptions\n"
    res += "    }\n"
    return res

  toString: =>
    resStr = ""
    resStr += @_generateMainStr()
    resStr += "\n"
    resStr += @_generateStatesStr()
    resStr += "\n"
    resStr += @_generateActionsStr()
    resStr += "\n"
    resStr += @_generateModelTypeStr()
    resStr += "\n"
    resStr += @_generateModelInplStr()
    resStr += "\n"

    resStr += "update : Msg -> Model -> ( Model, Cmd Msg )\n"
    resStr += "update msg model =\n"
    indentation = "  "
    resStr += indentation + "case ( model.state, msg ) of\n"
    indentation += "  "
    for transition in @transitions
      resStr += @_transitionToStr(transition, indentation)
    resStr += indentation + "_ ->\n" + indentation + "  model ! []\n"
    resStr += "\n"
    resStr += @_generateViewStr()
    return resStr

  generate: =>
    for line in @lines
      if line isnt "]" and line isnt "["
        @_addTransition(line)

    console.log @toString()
    return

  inputGenerated: (editor) =>
    console.log @toString()
    if (editor)
      editor.insertText(@toString())
