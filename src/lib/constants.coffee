module.exports = {
  CHANNEL_STATE:
    OPEN:    'open'
    CLOSED:  'closed'
    OPENING: 'opening'

  MaxFrameBuffer : 131072
  MaxEmptyFrameSize : 8

  AMQPTypes: Object.freeze({
    STRING:       'S'.charCodeAt(0)
    INTEGER:      'I'.charCodeAt(0)
    HASH:         'F'.charCodeAt(0)
    TIME:         'T'.charCodeAt(0)
    DECIMAL:      'D'.charCodeAt(0)
    BOOLEAN:      't'.charCodeAt(0)
    SIGNED_8BIT:  'b'.charCodeAt(0)
    SIGNED_16BIT: 's'.charCodeAt(0)
    SIGNED_64BIT: 'l'.charCodeAt(0)
    _32BIT_FLOAT: 'f'.charCodeAt(0)
    _64BIT_FLOAT: 'd'.charCodeAt(0)
    VOID:         'v'.charCodeAt(0)
    BYTE_ARRAY:   'x'.charCodeAt(0)
    ARRAY:        'A'.charCodeAt(0)
    TEN:          '10'.charCodeAt(0)
    BOOLEAN_TRUE: '\x01'
    BOOLEAN_FALSE:'\x00'
  })

  Indicators: Object.freeze({
    FRAME_END: 206
  })

  FrameType: Object.freeze({
    METHOD:    1
    HEADER:    2
    BODY:      3
    HEARTBEAT: 8
  })

  HeartbeatFrame : new Buffer([8,0,0,0,0,0,0,206])
  EndFrame       : new Buffer([206])
}

module.exports.MaxFrameSize = module.exports.MaxFrameBuffer - module.exports.MaxEmptyFrameSize
