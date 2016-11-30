fs = require 'fs'
path = require 'path'
{langdef, langmap} = require './ctags'

# RegExp to capture any arguments within () or within []
argsRe = {
  '()': "(\([^)]+\))"
  '[]': "(\[[^\]]+\])"
}
indentSpaceRe = "^(?: |\t)*"
positionRe = []
for i in [0..9]
  positionRe[i] = new RegExp('%' + i, 'g')

SmGenerator = require './sm-generator'
SmState = require './sm-state'

module.exports =
class NavParser
  pathObserver: null
  # projectRules: {}
  smGenerator: new SmGenerator()
  smState: new SmState()

  constructor: ->
    return

  parse: ->
    # TODO: FIX THAT, erasing the old one
    @smGenerator = new SmGenerator()
    @smState = new SmState()
    # parse active editor's text
    items = []
    editor = atom.workspace.getActiveTextEditor()
    return items unless editor
    editorFile = editor.getPath()
    return unless editorFile  # happens with new file

    activeRules = langdef.All or []
    markerIndents = []    # indent chars to track parent/children

    prevIndent = 0
    for ext in Object.keys(langmap)
      if editorFile.lastIndexOf(ext) + ext.length is editorFile.length
        activeRules = activeRules.concat(langmap[ext])
        break

    for row in [0..editor.getLineCount() ]
      lineText = editor.lineTextForBufferRow(row)

      originalLine = lineText

      lineText = lineText.trim() if lineText
      continue unless lineText

      @smGenerator.parseLine(originalLine)
      @smState.parseLine(originalLine)

      if lineText.indexOf('#' + 'marker-rule:') >= 0
        newRule = @parseRule(lineText)
        if newRule
          updateRules(newRule)
          continue

      # Track indent level
      indent = lineText.match(indentSpaceRe)[0].length
      while indent < prevIndent
        prevIndent = markerIndents.pop()

      for rule in activeRules
        match = lineText.match(rule.re)
        if match
          parentIndent = -1
          markerIndents.push(indent) if indent > prevIndent
          if markerIndents.length > 1
            parentIndent = markerIndents[markerIndents.length-2]
          items.push @makeItem(rule, match, lineText, row, indent, parentIndent)
    @smGenerator.generate()
    # @smState.
    return items


  makeItem: (rule, match, text, row, indent, parentIndent) ->
    label = rule.id or ''
    tooltip = rule.tooltip or ''
    icon = rule.icon #|| 'primitive-dot'
    if label or tooltip
      for str, i in match
        if label
          label = label.replace(positionRe[i], match[i])
        if tooltip
          tooltip = tooltip.replace(positionRe[i], match[i])
    unless label
      label = match[1] or match[0]

    kind = rule.kind or 'Markers'

    if rule.args
      argsMatch = argsRe[rule.args].exec(text)
      tooltip += argsMatch[1] if argsMatch

    item = {label: label, icon: icon, kind: kind, row: row
      , tooltip: tooltip, indent: indent, parentIndent: parentIndent}


  parseRule: (line) ->
    # Should be: '#marker-rule' followed by colon, then by regular expression
    # followed by optional fields separated by ||
    # optional fields are
    # identifier (label) which must have one of %1 through %9 if present
    # kind : e.g. Function. Default is 'Markers'
    # startOver : The literal text 'startOver'. Discards any previous rules
    # disable=kind1,kind2 : Disable specified kinds
    # ext=.coffee,.js
    return unless line
    ruleStr = line.split('#' + 'marker-rule:')[1].trim()
    return unless ruleStr
    parts = ruleStr.split('||')
    reFields = parts[0].match("[ \t]*\/(.+)\/(.*)")
    if not reFields and ruleStr.search("(^|\|\|)(startOver|disable=)") is -1
      console.log 'Navigator Panel: No regular expression found in :', line
      return
    rule = {}
    if reFields
      reStr = reFields[1] #.replace(/\\/g, '\\\\')
      flag = 'i' if reFields[2]
      rule = {re: new RegExp(reStr, flag)}
      parts.shift()

    for part in parts
      if part.indexOf('%') isnt -1
        rule.id = part
      else if part.indexOf('startOver') is 0
        rule.startOver = true
      else if part.indexOf('disable=') is 0
        rule.disableGroups = part.substr('disable='.length).split(',')
      else if part.indexOf('ext=') is 0
        rule.ext = part.substr('ext='.length).split(',')
      else
        rule.kind = part
    return rule


  destroy: ->
    @pathObserver.dispose()
