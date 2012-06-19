config       = require("../config.json")
config.debug = process.env.DEBUG ? false
config.log   = process.env.LOG ? false

VDubsId      = config.userids.vdubs
AUTH         = config.auths[process.argv[2]]
USERID       = config.userids[process.argv[2]]

##  Room object
room = null
initroom = () ->
  room =
    id: null
    name: null
    song:
      room_vote_percentage: () ->
        Math.round (room.votes.us - room.votes.down + room.listeners) / (2 * room.listeners) * 100
      name: null
      artist: null
    dj:
      name: null
      id: null
    votes:
      up: 0
      down: 0
    snags: 0
    listeners: 0
  moderators: []
  djs: []
  init: (data) ->
    null

## Speaker object.  Initialized on('speak')
speaker:
  name: null
  id: null
  text: null
  init: (data) ->
    speaker.name = data.name
    speaker.id   = data.userid
    speaker.text = data.text

## Room object.  Initialized on('roomChanged')
bot = newbot AUTH, USERID

newbot = (auth, user, room...) ->
  Bot = require("../lib/ttapi/index")
  bot = try
    new Bot(auth, user, room)
  catch error
    new Bot(auth, user)
  bot.vote = 0
  bot.snagged = bot.autodj = bot.autobop = bot.isSnarky = bot.isFriendly = bot.isGrateful = bot.djAnnounce = bot.djGoodbye = bot.likes_to_drink false

  bot.reset = () ->
    bot.votes = 0
    bot.vote_attempts = 0

  bot.upvote = () ->
    return false if bot.votes == 1

    time = wait()
    log "#### Bop on @ " + time / 1000 + " #####"

    dovote = () ->
      bot.vote('up', (data) ->
        debug "Checking vote response: " + data
        bot.vote_attempts += 1
        if data.err isnt "Cannot vote on your song" and data.err isnt "User has already voted up"
          bot.votes = 0
          log "Retrying vote"
          bot.upvote unless bot.vote_attemtps > 5
        else
          bot.votes = 1
          vote_commentary
      )
    setTimeout dovote, time

  bot.downvote = () ->
    return false if bot.votes == -1
    bot.vote('down')
    bot.votes = -1

  bot.down = () ->

  bot.have_a_drink = () ->
    if text.match(/.j refreshing *(bud|hein|coor|coron|beer|glass of milk|cup of urine)/)
      if bot.likes_to_drink
        if rand() % 2 is 0
          setTimeout () -> bot.speak "I don't usually drink on the job... but ok, thanks " + data.name + "!", wait(1, 3)
        else
          setTimeout () -> bot.speak "w00t! Let's get wasted!", wait(1, 3)
      bot.upvote

  bot.doautodj = () ->
    return if bot.autodj is false
    i_a_dj = (if room.djs.indexOf(bot.userId) isnt -1 then true else false)
    threshold = data.room.metadata.max_djs - 1
    if im_a_dj
      if data.room.metadata.djcount > threshold
        if data.room.metadata.current_dj is bot.userId
          bot.speak "Turtles after this song!"
          bot.on "endsong", djDown
        else
          console.log "####  Too many djs.  Getting down. ####"
          bot.speak "Who likes turtles?"
          setTimeout djDown, wait()
    else if data.room.metadata.djcount < threshold
      console.log "#####  I'm getting up: " + data.room.metadata.djcount + " < " + threshold + "  ####"
      setTimeout bot.speak("Looks like there's room for me!  w00t!"), wait()
      bot.addDj()
    else
      console.log "####  Not doing anything: " + data.room.metadata.djcount + " of " + data.room.metadata.max_djs + " spots taken"

  bot.eat_subasnack = () ->
    if speaker.text.match(/\.j subasnack/)
      if bot.isGrateful
        setTimeout () -> bot.speak "Thanks for the subasnack " + data.name + "!", wait(1, 2)
      bot.upvote


  bot.announce_stats = () ->
    console.log "\n#### Speaking song stats ####"
    bot.speak room.song.artist + "  ::  " + room.song.name + " Received  -  Ups: " + room. "  |  Downs: " + room_data.downvotes + "  -  That's a " + Math.round(percent) + "% room rating"

  bot.snag_song = () ->
    if percent >= snag
      unless snag is false
        bot.playlistAll (data) ->
        bot.playlistAdd current_song._id, data.list.length
        debulog "\n#### Added song ####\n " + current_song.metadata.artist + " // " + current_song.metadata.song + " :: " + Math.round(percent) + "\n"

  bot.do_dj_announce = () ->
    announce = "Hi " + data.user[0].name + ".  Enjoy your time on stage.  Respect the other djs!"  unless announce
    setTimeout (->
      bot.speak announce
    ), wait(1, 4)

  bot.log_song_info = () ->
    console.log "\n#### Logging song stats ####"
    console.log current_song.metadata.artist + "  ::  " + current_song.metadata.song + " -  Ups: " + room_data.upvotes + "  |  Downs: " + room_data.downvotes + "  -  " + Math.round(percent) + "% room rating"

  return bot

log = (msg) ->
  console.log msg if config.log

debug = (msg) ->
  console.log msg if config.debug


##  Be a bit talkative regarding our vote
vote_commentary = () ->
  return false unless bot.isSnarky
  switch time / 1000
    when 1
      bot.speak "This song is awesome!"
    when 2
      bot.speak "Turtle bacon anyone?"
    when 3
      bot.speak "Dancing is fun"
    when 4
      bot.speak "Oooooh is this the Pearls Jams?"
    when 5
      bot.speak "b0rT!!??"
    when 6
      bot.speak "When can I play some music?"
    when 7
      bot.speak ":fire:"
    when 8
      bot.speak "/q please?"
    when 9
      bot.speak "I like turtles!"

rand = (min, max) ->
  min = 1  unless min
  max = 6  unless max
  Math.floor Math.random() * (max - min + 1) + min

wait = (min, max) ->
  min = 1  unless min
  max = 6  unless max
  rand(min, max) * 1000

################################################################################
##
##                          EVENTS CALLBACKS
##
################################################################################

##  When entering a new room, reset:
#     - the bot
#     - the room
#     - the speaker
bot.on 'roomChanged', (data) ->
  bot.init(data)
  room.init(data)
  speaker.init(data)

##  When someone speaks, init the speaker object with new data
bot.on 'speak', () ->
  if text.match(/sub.* bot/i)
    setTimeout (->
      bot.speak "Hells no!!"
    ), wait()

  if text.match(/\.j botsnack/)
    if isGrateful
      if rand() % 4 is 0
        setTimeout (->
          bot.speak "Can I have a subasnack too please?"
        ), 1000
  if text.match(/.j subawater/)
    if isGrateful
      if rand() % 2 is 0
        setTimeout (->
          bot.speak "I appreciate the gesture, but don't you have something a little stronger?"
        ), wait(1, 3)
      else
        setTimeout (->
          bot.speak "Thanks " + data.name + ".  All those subasnacks were making me thirsty."
        ), wait(1, 3)
    upvote false

##  When someone speaks, perhaps respond

bot.on 'speak', bot.eat_subasnack
bot.on 'speak', bot.
bot.on 'speak', () ->
  console.log speaker.text if bot.logging_enabled

bot.on "add_dj", doautodj
bot.on "rem_dj", doautodj
bot.on "endsong", doautodj
bot.on "add_dj", (data) ->
bot.on "rem_dj", (data) ->
  unless djgoodbye is "off"
    bye = djgoodbye
    bye = "Thanks for playing " + data.user[0].name + " :)"  unless bye
    setTimeout (->
      bot.speak bye
    ), wait(1, 4)

bot.on "endsong", (data) ->
  bot.announce_stats

bot.on 'newsong', () -> bot.do_auto_vote

bot.on "newsong", -> bot.removeListener "endsong", djDown

bot.on "pmmed", (data) ->
  text = data.text
  console.log "#### Received PM: ####\n" + text
  senderid = data.senderid
  if senderid is VDubsId
    command = false
    arg = false
    extra_args = false
    match = text.match(/^\.(\S+) *(.*)/)
    if match
      command = match[1]
      arg = match[2]
      if command isnt "speak" and match[2]
        match = arg.match(/^(\S+) *(.*)/)
        arg = match[1]
        extra_args = match[2]
    if command
      switch command
        when "snag"
          bot.snag()
        when "speak"
          bot.speak arg
        when "auto"
          doautodj()
        when "up"
          bot.addDj()
          bot.speak "WooHoo!"
        when "down"
          djDown()
          bot.speak ":poop: :fire:"
        when "dance"
          bopcount = 0
          upvote false
        when "lame"
          bot.vote "down"
        when "skip"
          bot.skip()
          bot.pm "Skipping song", senderid
        when "dequeue"
          bot.playlistRemove 0
          bot.pm "Removing song from queue", senderid
        when "set"
          switch arg
            when "avatar"
              bot.setAvatar extra_args
              bot.pm "Set avatar to: " + extra_args, senderid
            when "friendly"
              isFriendly = not isFriendly
              bot.pm "Friendly set to: " + isFriendly, senderid
              console.log "Friendly set to: " + isFriendly
            when "chatty"
              isChatty = not isChatty
              bot.pm "Chatty set to: " + isChatty, senderid
              console.log "Chatty set to: " + isChatty
            when "grateful"
              isGrateful = not isGrateful
              bot.pm "Grateful set to: " + isGrateful, senderid
              console.log "Grateful set to: " + isGrateful
            when "snide"
              isSnide = not isSnide
              bot.pm "Snide set to: " + isSnide, senderid
              console.log "Snide set to: " + isSnide
            when "autodj"
              autodj = not autodj
              autobop = autodj
              bot.pm "Autodj set to: " + autodj, senderid
              bot.pm "Autobop set to: " + autobop, senderid
              console.log "Autodj set to: " + autodj
              doautodj()
              doAutoBop autobop
            when "djannounce"
              djannounce = extra_args
              message = "Changing DJ Announce to: " + djannounce
              bot.pm message, senderid
              console.log message
            when "djgoodbye"
              djgoodbye = extra_args
              message = "Changing DJ Goodbye to: " + djannounce
              bot.pm message, senderid
              console.log message
            when "snag"
              snag = extra_args
              message = "Changing snag threshold to: " + snag
              bot.pm message, senderid
              console.log message
            when "snag"
              snag = extra_args
              message = "Changing snag threshold to: " + snag
              bot.pm message, senderid
              console.log message
            when "room"
              room = extra_args
              if room.length is 24
                id = room
              else
                id = config.rooms[room]
              unless id
                bot.pm "I dont know about room " + room, senderid
                break
              message = "Moving over to: " + room + ": " + id
              bot.pm message, senderid
              console.log message
              bot.roomRegister id
            when "autobop"
              autobop = not autobop
              doAutoBop autobop
        when "show"
          switch arg
            when "chatty"
              bot.pm isChatty, senderid
            when "djannounce"
              bot.pm djannounce, senderid
            when "djgoodbye"
              bot.pm djgoodbye, senderid
            when "grateful"
              bot.pm isGrateful, senderid
            when "friendly"
              bot.pm isFriendly, senderid
            when "queue"
              bot.playlistAll (data) ->
                console.log data
            when "fans"
              bot.getFans (data) ->
                console.log data
            when "snag"
              bot.pm "Snag @ " + snag, senderid
            when "snide"
              bot.pm "Snide @ " + isSnide, senderid
            when "autodj"
              bot.pm "Autodj @ " + autodj, senderid
            when "autobop"
              bot.pm "Autobop @ " + autobop, senderid
            when "rooms"
              for room of config.rooms
                bot.pm room, senderid
  else
    bot.pm "Sorry... I'm not allowed to talk to strangers!", senderid

bot.on "speak", (data) ->
  speaker.init data

