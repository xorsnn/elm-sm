# Created by ctags2coffee.coffee by processing .ctags
langdef =
  All: [
    {re: new RegExp("#nav-mark:(.*)", "i"), id: '%1', kind: 'Markers'}
    {re: new RegExp("#todo:(.*)", "i"), id: '%1', kind: 'Todo'}
  ]
  Elm: [
    {re: new RegExp("^((?!(update|view|init|(\\w+View)))\\w+)\ :\ .+"), id: '%1', kind: 'Function'}
    {re: new RegExp("^(\\w+View)\ :\ .+"), id: '%1', kind: 'Views'}
    {re: new RegExp("^(update|view|init)\ :\ .+"), id: '%1', kind: 'Biuld-in function'}
    {re: new RegExp("(\\w+Msg)\ .*->.*"), id: '%1', kind: 'Messages'}
    {re: new RegExp("(\\w+Input)\ .*->.*"), id: '%1', kind: 'Inputs'}
    {re: new RegExp("(SM\ diagram)"), id: '%1', kind: 'Diagram'}
  ]

langmap =
  '.elm': langdef.Elm

module.exports = {langdef: langdef, langmap: langmap}
