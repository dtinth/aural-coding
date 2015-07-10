
_ = require 'lodash'

data = require('../pieces/debussy_clairdelune.json')

raw =
_.chain(data.pieceData)
.chunk 4
.map ([start, end, note, velocity]) ->
  [
    { time: start, note, velocity, on: true }
    { time: end, note, velocity, on: false }
  ]
.flatten()
.sortBy(['time', 'order'])
.value()

createEvent = -> { on: [], off: [] }
currentEvent = createEvent()
events = [ currentEvent ]
lastTime = _.chain(raw).map('time').min().value()
offQueue = []

for current in raw
  if current.on and current.time > lastTime
    lastTime = current.time
    currentEvent = createEvent()
    currentEvent.off.push offQueue...
    offQueue = []
    events.push currentEvent
  if current.on
    currentEvent.on.push current
  else
    # currentEvent.off.push current
    offQueue.push current

exports.events = events
