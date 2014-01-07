should  = require('should')
async    = require('async')
_        = require('underscore')
proxy    = require('./proxy')
uuid = require('node-uuid').v4

AMQP = require('src/amqp')

{ MaxFrameBuffer, FrameType, HeartbeatFrame }   = require('../src/lib/config').constants

describe 'Publisher', () ->

  it 'test we can publish a message in confirm mode', (done)->
    amqp = null
    queue = uuid()
    async.series [
      (next)->
        amqp = new AMQP {host:'localhost'}, (e, r)->
          should.not.exist e
          next()
    
      (next)->
        amqp.publish "amq.direct", queue, "test message", {confirm:true}, (e,r)->
          should.not.exist e
          next() 

    ], done


  it 'we can publish a series of messages in confirm mode', (done)->
    amqp = null
    queue = uuid()
    async.series [
      (next)->
        amqp = new AMQP {host:'localhost'}, (e, r)->
          should.not.exist e
          next()
    
      (next)->
        async.forEach [0...100], (i, done)->
          amqp.publish "amq.direct", queue, "test message", {confirm:true}, (e,r)->
            should.not.exist e
            done()
        , next 

    ], done


  it 'we can agressivly publish a series of messages in confirm mode 214', (done)->
    amqp = null
    queue = uuid()
    done = _.once done

    amqp = new AMQP {host:'localhost'}, (e, r)->
      should.not.exist e

      amqp.queue {queue}, (e,q)->
        q.declare ()->
          q.bind "amq.direct", queue, ()->
            i = 0
            j = 0
            while i <= 100
              amqp.publish "amq.direct", queue, {b:new Buffer(500)}, {deliveryMode:2, confirm:true}, (e,r)->
                should.not.exist e
                j++
                if j >=100
                  done()

              i++ 


  it 'test we can publish a message a string', (done)->
    amqp = null
    queue = uuid()
    async.series [
      (next)->
        amqp = new AMQP {host:'localhost'}, (e, r)->
          should.not.exist e
          next()
    
      (next)->
        amqp.publish "amq.direct", queue, "test message", {}, (e,r)->
          should.not.exist e
          next() 

    ], done


  # it 'test we can publish a big string message', (done)->
  #   amqp = null
  #   queue = uuid()
  #   async.series [
  #     (next)->
  #       amqp = new AMQP {host:'localhost'}, (e, r)->
  #         should.not.exist e
  #         next()
    
  #     (next)->
  #       amqp.publish "amq.direct", queue, "test message #{new Buffer(10240000).toString()}", {confirm: true}, (e,r)->
  #         should.not.exist e
  #         next() 

  #   ], done


  it 'test we can publish a JSON message', (done)->
    amqp = null
    queue = uuid()
    async.series [
      (next)->
        amqp = new AMQP {host:'localhost'}, (e, r)->
          should.not.exist e
          next()
    
      (next)->
        amqp.publish "amq.direct", queue, {look:"im jason", jason:"nope"}, {}, (e,r)->
          should.not.exist e
          next() 

    ], done


  it 'test we can publish a buffer message', (done)->
    amqp = null
    queue = uuid()
    async.series [
      (next)->
        amqp = new AMQP {host:'localhost'}, (e, r)->
          should.not.exist e
          next()
    
      (next)->
        amqp.publish "amq.direct", queue, new Buffer(15), {}, (e,r)->
          should.not.exist e
          next() 

    ], done


  it 'test we can publish a buffer message that need to be multiple data packets', (done)->
    amqp = null
    queue = uuid()
    packetSize = MaxFrameBuffer * 2.5
    async.series [
      (next)->
        amqp = new AMQP {host:'localhost'}, (e, r)->
          should.not.exist e
          next()
    
      (next)->
        amqp.publish "amq.direct", uuid(), new Buffer(packetSize), {}, (e,r)->
          should.not.exist e
          next() 

    ], done


  it 'test we can publish a message size 344', (done)->
    amqp = null
    queue = uuid()
    packetSize = 344
    async.series [
      (next)->
        amqp = new AMQP {host:'localhost'}, (e, r)->
          should.not.exist e
          next()
    
      (next)->
        amqp.publish "amq.direct", uuid(), new Buffer(packetSize), {confirm: true}, (e,r)->
          should.not.exist e
          next() 

    ], done


  it 'test we can publish a lots of messages in confirm mode 553', (done)->
    this.timeout(5000)
    amqp = null
    queue = uuid()
    packetSize = 344
    async.series [
      (next)->
        amqp = new AMQP {host:'localhost'}, (e, r)->
          should.not.exist e
          next()
    
      (next)->
        async.forEach [0...1000], (i, next)->
          amqp.publish "amq.direct", "queue-#{i}", new Buffer(packetSize), {confirm: true}, (e,r)->
            should.not.exist e
            next() 
        , next

    ], done


  it 'test we can publish a lots of messages in confirm mode quickly 187', (done)->
    this.timeout(5000)
    amqp = null
    queue = uuid()
    packetSize = 256837

    amqp = new AMQP {host:'localhost'}, (e, r)->
      should.not.exist e

      async.forEach [0...10], (i, next)->
        amqp.publish "amq.direct", "queue-#{i}", new Buffer(packetSize), {confirm: true}, (e,r)->
          should.not.exist e
          next() 
      , done



  it 'test we can publish a mandatory message to a invalid route and not crash', (done)->
    amqp = null
    queue = null
    async.series [
      (next)->
        amqp = new AMQP {host:'localhost'}, (e, r)->
          should.not.exist e
          next()
    
      (next)->
        amqp.publish "amq.direct", "idontExist", new Buffer(50), {confirm:true, mandatory: true}, (e,r)->
          should.not.exist e
          next() 

    ], done

  it 'test when be publishing and an out of order op happens we recover', (done)->
    this.timeout(4000)
    amqp = null

    testData = {test:"message"}
    amqp = null
    queue = uuid()
    messagesRecieved = 0
    consumer = null
    q= null
    messageProcessor = (m)->
      m.data.should.eql testData
      messagesRecieved++

      if messagesRecieved is 3
        q.connection.crashOOO()

      if messagesRecieved is 55
        done()

      m.ack()

    async.series [
      (next)->
        amqp = new AMQP {host:'localhost'}, (e, r)->
          should.not.exist e
          next()
    
      (next)->
        q = amqp.queue {queue, autoDelete:false}, (e,q)->
          q.declare ()->
            q.bind "amq.direct", queue, next

      (next)->
        async.forEach [0...5], (i, done)->
          amqp.publish "amq.direct", queue, testData, {confirm: true}, (err, res)->
            # console.error "#{i}", err, res
            if !err? then return done() else 
              setTimeout ()->
                amqp.publish "amq.direct", queue, testData, {confirm: true}, (err, res)->
                # console.error "*#{i}", err, res
                  done(err,res)
              , 200
        , next

      (next)->
        consumer = amqp.consume queue, {prefetchCount: 1}, messageProcessor, (e,r)->
          should.not.exist e
          next() 

      (next)->
        async.forEach [0...50], (i, done)->
          amqp.publish "amq.direct", queue, testData, {confirm: true}, (err, res)->
            # console.error "#{i}", err, res
            if !err? then return done() else
              setTimeout ()->
                amqp.publish "amq.direct", queue, testData, {confirm: true}, (err, res)->
                # console.error "*#{i}", err, res
                  done(err,res)
              , 200
        , next

    ], (err,res)->
      # console.error "DONE AT THE END HERE", err, res
      should.not.exist err


  it 'test when an out of order op happens while publishing large messages we recover 915', (done)->
    this.timeout(4000)
    amqp = null

    testData = {test:"message", size: new Buffer(1000)}
    amqp = null
    queue = uuid()
    messagesRecieved = 0
    consumer = null
    q= null

    messageProcessor = (m)->
      # m.data.should.eql testData
      messagesRecieved++

      if messagesRecieved is 100
        q.connection.crashOOO()

      if messagesRecieved is 500
        done()

      m.ack()

    async.series [
      (next)->
        amqp = new AMQP {host:'localhost'}, (e, r)->
          should.not.exist e
          next()
    
      (next)->
        q = amqp.queue {queue, autoDelete:false}, (e,q)->
          q.declare ()->
            q.bind "amq.direct", queue, next

      (next)->
        consumer = amqp.consume queue, {prefetchCount: 1}, messageProcessor, (e,r)->
          should.not.exist e
          next() 

      (next)->
        async.forEach [0...500], (i, done)->
          amqp.publish "amq.direct", queue, testData, {confirm: true}, (err, res)->
            if !err? then return done() else
              setTimeout ()->
                amqp.publish "amq.direct", queue, testData, {confirm: true}, (err, res)->
                  done(err,res)
              , 200
        , next

    ], (err,res)->
      # console.error "DONE AT THE END HERE", err, res
      should.not.exist err


