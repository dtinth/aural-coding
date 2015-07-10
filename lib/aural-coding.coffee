
midi = require 'midi'

output = new midi.output()
output.openVirtualPort('aural-coding-midi')

_ = require 'lodash'
song = require './song'

module.exports =
class AuralCoding
  constructor: ->
    @firstKey = 0x15
    @lastKey = 0x6C
    @i = 0
    @sources = { }

    @majorScaleNotes = [@firstKey...@lastKey].filter (key, index) =>
      ((index + 4) % 12) in [0,2,4,5,7,9,11] # C Major Scale. (I think?)

    atom.views.getView(atom.workspace).addEventListener 'keydown', ((e) => @noteOn(e)), true
    atom.views.getView(atom.workspace).addEventListener 'keyup', ((e) => @noteOff(e)), true

  noteForEvent: (key, modifiers) ->
    return unless key

    if /^[a-z]$/i.test key
      keyCode = key.toUpperCase().charCodeAt(0)
      index = 24 + (keyCode - 'A'.charCodeAt(0)) % 12
      index += 12 if /[A-Z]/.test key
      return { note: @majorScaleNotes[index], channel: 1, velocity: 0.75 }
    else
      [index, velocity] = switch key
        when 'backspace' then [50, 1]
        when 'delete' then [49, 1]
        when 'space' then [41, 0.025]
        when '\t' then [41]
        when '.' then [56]
        when '"' then [57]
        when '\'' then [58]
        when '+' then [61]
        when '[' then [36]
        when ']' then [37]
        when '(' then [38]
        when ')' then [39]
        when '!' then [54, 2]
        else [45]

      return { note: index, velocity: velocity ? 0.2, channel: 10 }

  noteOn: (event) ->
    return if event.metaKey
    {key, modifiers} = @keystrokeForKeyboardEvent(event)
    return unless key
    return if @sources[event.which]
    @current() if @current
    note = song.events[@i % song.events.length]
    @current = @go(note)
    @sources[event.which] = true

  go: (event) ->
    @midi([0x90, note.note, note.velocity]) for note in event.on
    =>
      @midi([0x90, note.note, 0]) for note in event.off

  noteOff: (event) ->
    delete @sources[event.which]
    if @current and Object.keys(@sources).length is 0
      @current()
      delete @current

  note: (channel, note, velocity) ->
    @midi([0x90 + channel - 1, note, velocity])
    =>
      @midi([0x90 + channel - 1, note, 0])

  midi: (message) ->
    # console.log(message)
    output.sendMessage(message)

  keystrokeForKeyboardEvent: (event) ->
    keyIdentifier = event.keyIdentifier
    if keyIdentifier.indexOf('U+') is 0
      hexCharCode = keyIdentifier[2..]
      charCode = parseInt(hexCharCode, 16)
      charCode = event.which if not @isAscii(charCode) and @isAscii(event.which)
      key = @keyFromCharCode(charCode)
    else
      key = keyIdentifier.toLowerCase()

    modifiers = []
    modifiers.push 'ctrl' if event.ctrlKey
    modifiers.push 'alt' if event.altKey
    if event.shiftKey
      # Don't push 'shift' when modifying symbolic characters like '{'
      modifiers.push 'shift' unless /^[^A-Za-z]$/.test(key)
      # Only upper case alphabetic characters like 'a'
      key = key.toUpperCase() if /^[a-z]$/.test(key)
    else
      key = key.toLowerCase() if /^[A-Z]$/.test(key)

    modifiers.push 'cmd' if event.metaKey

    key = null if key in ['meta', 'shift', 'control', 'alt']

    {key, modifiers}

  keyFromCharCode: (charCode) ->
    switch charCode
      when 8 then 'backspace'
      when 9 then 'tab'
      when 13 then 'enter'
      when 27 then 'escape'
      when 32 then 'space'
      when 127 then 'delete'
      else String.fromCharCode(charCode)

  isAscii: (charCode) ->
    0 <= charCode <= 127
