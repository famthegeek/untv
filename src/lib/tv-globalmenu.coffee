###
UNTV - tv-globalmenu.coffee
Author: Gordon Hall

Injects the global menu interface and subscribes to events from
the remote control bus
###

$              = require "../vendor/jquery-2.0.3.js"
{EventEmitter} = require "events"
jade           = require "jade"
fs             = require "fs"
extend         = require "node.extend"
PanelExtension = require "./tv-panelextension"

class GlobalMenu extends EventEmitter

  constructor: (@container, @remote, @player) ->
    @extensions = []
    @visible    = no
    # subscribe to remote events
    @remote.on "menu:open", @open
    @remote.on "menu:close", @close
    @remote.on "go:next", @select
    @remote.on "scroll:up", @focusPrev
    @remote.on "scroll:down", @focusNext

  render: =>
    view_path = "#{__dirname}/../views/globalmenu.jade"
    compiled  = jade.compile fs.readFileSync view_path
    html      = compiled items: @extensions
    @container.html? html
    ($ "li:first-of-type", @container).addClass "has-focus"

  addExtension: (path, manifest) =>
    # check manifest's main file here and store reference to it
    extension        = extend yes, {}, manifest
    init_script_path = "#{path}/#{extension.main}"
    if fs.existsSync init_script_path
      ext_init         = require init_script_path
      extension.main   = new (ext_init) @remote, @player, PanelExtension
      view_raw         = fs.readFileSync "#{path}/#{extension.view}"
      extension.view   = jade.compile view_raw.toString()

    @extensions.push extension if manifest and manifest.name
    do @render

  open: =>
    @container.addClass "visible" if not @visible
    @visible = yes

  close: =>
    @container.removeClass "visible" if @visible
    @visible = no

  focusNext: =>
    next_item = @current().next()
    if next_item.length and @visible
      @current().removeClass "has-focus"
      next_item.addClass "has-focus"

  focusPrev: =>
    previous_item = @current().prev()
    if previous_item.length and @visible
      @current().removeClass "has-focus"
      previous_item.addClass "has-focus"

  select: =>
    if not @visible then return
    index     = @current().index "li", @container
    extension = @extensions[index]
    # inject view
    extension.main.container.html extension.view()
    # call init script and close menu
    do @extensions[index].main?.activate
    do @close

  current: => $ "li.has-focus", @container

module.exports = GlobalMenu