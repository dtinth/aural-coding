
song = require '../lib/song'

describe "song", ->
  it "works", ->
    event = song.events[0]
    expect(event.on.length).toEqual(2)
    expect(event.off.length).toEqual(2)
