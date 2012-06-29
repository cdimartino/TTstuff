util = require('util')
Bot = require("../lib/ttapi/index")

config       = require("../config.json")
config.debug = process.env.DEBUG ? false
config.log   = process.env.LOG ? false

log = (msg) ->
  console.log msg if config.log

debug = (msg) ->
  console.log msg if config.debug

rand = (min, max) ->
  min = 1  unless min
  max = 6  unless max
  Math.floor Math.random() * (max - min + 1) + min

wait = (min, max) ->
  min = 1  unless min
  max = 6  unless max
  rand(min, max) * 1000

VDubsId = config.userids['vdubs']
[auth_arg, room_arg]  = process.argv[2..3]
AUTH    = config.auths[auth_arg]
USERID  = config.userids[auth_arg]
ROOM    = if room_arg then config.rooms[room_arg] else null

#################################################################################
###   TTBot class
#################################################################################
class TTBot extends Bot
  dance_matches: ['bop', 'dance', 'boogie', 'waltz', 'mosh', 'stagedive', 'thrash', 'salza', 'trance', 'stance', 'shake', 'rattle', 'roll', 'bounce']
  userId: null
  authId: null
  roomId: null
  votes: 0
  vote_attempts: 0
  room_rules: "Play whatever you want, as long as it's alt/grunge/indie/etc from the 80's to current. Respect your other DJ's on stage - show them some love - awesome their songs! And show @subadubadoo some respect! He loves to dance and eat and imbibe various liquids."
  toggles: {
    autodj: false
    autobop: false
    do_dj_announce: false
    friendly: true
    snarky: false
    grateful: true
    chatty: true
    likes_to_drink: true
  }
  djannounce: "Welcome! Play good music, awesome every song, don't be a dick."
  djgoodbye: false
  autodj_threshold: 2

  constructor: (@userId, @authId, @roomId) ->
    @interact = new Interactivity this
    super(@userId, @authId, @roomId)

  reset: () ->
    @votes = 0
    @vote_attempts = 0

  update: (data, cb) ->
    if data
      #debug "Updating bot with data: #{util.inspect data, true, 5}"
      if data.room
        #debug "Room info before update: #{util.inspect @room}"
        if @room
          @room.update data.room
        else
          @room = new Room data.room
          #debug "Room info after update: #{util.inspect @room}"

      if data.speaker
        #debug "Speaker info before updte: #{util.inspect @speaker}"
        @speaker = new Speaker data.speaker.userid, data.speaker.name, data.speaker.text
        #debug "Speaker info after updte: #{util.inspect @speaker}"

      if data.pm
        #debug "PM info before update: #{util.inspect @pm_obj}"
        @pm_obj= new Pm data.pm, @room, this
        #debug "PM info after update: #{util.inspect @pm_obj}"
    else
      @roomInfo (data) => @update {room: data}

    #operator: new Operate this
    #moderator: new Moderate this
    if cb
      cb()

  operate: () =>
    @interact.question_ones_makeup()
    @interact.eat_a_subasnack()
    @interact.drink_some_water()
    @interact.drink_some_booze()
    @interact.time_to_dance()
    @interact.what_are_the_rules()
    #    @operator.do @speaker
    #    @moderator.do @speaker

  upvote: () ->
    return false if @votes == 1
    time = wait()
    debug "#### Bopping in #{time / 1000} sec #####"

    do_vote = () =>
      @vote('up', (data) =>
        debug "Checking vote response: " + util.inspect data, false, null
        @vote_attempts += 1
        if data.err
          if not data.err in ["Cannot vote on your song", "User has already voted up"]
            @votes = 0
            log "Retrying vote"
            @upvote() unless @vote_attemtps > 5
        else
          @votes = 1
          @interact.vote_commentary()
      )
    setTimeout do_vote, time

  downvote: () ->
    return false if @votes == -1
    @vote('down')
    @votes = -1

  dj_down: () -> @remdDj USERID

  dj_up: () -> @addDj()

  do_new_song: (data) ->
    @update {room: data}
    @reset()

  do_end_song: () ->
    @interact.announce_stats()
    @autodj()
  ##  Returns:
  ##    1  : djup
  ##    0  : no action
  ##    -1 : djdown
  autodj_action: () ->
    return -1 if not @autodj and @im_a_dj()
    if @im_a_dj
      if @open_slots() < @autodj_threshold + 1
        return -1
      else
        return 0
    else
      if @open_slots() <= @autodj_threshold
        return 1

  open_slots: () -> @room.max_djs - @room.djcount

  im_a_dj: () ->
    if @room.djs.indexOf(@userId) isnt -1 then true else false

  autodj: () ->
    switch @autodj_action()
      when -1
        if @room.current_dj is @userId
          @speak "Turtles after this song!"
          cb = -> @dj_down
          @on "endsong", cb
          @on "newsong", -> @once "endsong", cb
        else
          debug "####  Too many djs.  Getting down. ####"
          @speak "Who likes turtles?"
          setTimeout @dj_down, wait(2,6)
      when 1
        log "#####  I'm getting up to autodj.  Current slots: #{@open_slots()}  Threshold: #{@autodj_threshold}  ####"
        setTimeout @speak("Looks like there's room for me!  w00t!"), wait()
        @dj_up()

#  snag_song: () ->
#    #      if percent >= snag
#    #        unless snag is false
#    #          @playlistAll (data) ->
#    #            @playlistAdd @room.song.id, data.list.length
#    #          debug "\n#### Added song ####\n " + current_song.metadata.artist + " // " + current_song.metadata.song + " :: " + Math.round(@room.vote_percentage) + "\n"
#    #

  do_new_dj: (data) =>
    #@do_auto
    @interact.do_dj_announce(data.user[0].name)

  do_pm_action: () =>
    m = new Moderate this
    @pm_obj.decide (pm) =>
      m.do pm

  song_recap: () ->
    "#{@room.dj.name} Played: #{@room.song.artist} -- #{@room.song.name} -- :thumbsup:: #{@room.votes.up} :thumbsdown:: #{@room.votes.down} :heart:: #{@room.snags} :tomato:: #{Math.round(@room.vote_percentage())}%"

  log_song_info: () ->
    debug "#### Logging song stats ####"
    log @song_recap()

  toggle: (which) ->
    @toggles[which] = not @toggles[which]
    debug util.inspect @toggles

  update_votes: (data) -> @room.update_votes(data)


#################################################################################
###   Interactivity class
#################################################################################
class Interactivity
  constructor: (@bot) ->

  announce_stats: () =>
    debug "#### Speaking song stats ####"
    if @bot.toggles.chatty
      @bot.speak @bot.song_recap()
    log @bot.song_recap()

  do_dj_announce: (name) =>
    if @bot.toggles.do_dj_announce
      if @bot.djannounce?
        cb = () => @bot.speak("Hi #{name}.  " + @bot.djannounce)
        setTimeout cb, 2000

  do_dj_goodbye: () =>
    cb = () => @bot.speak @bot.djgoodbye
    setTimeout cb, 2000

  drink_some_booze: () =>
    if @bot.speaker.text.match(/.j refreshing /)
      if @bot.toggles.likes_to_drink
        msg = switch rand() % 3
                when 0 then "I don't usually drink on the job... but ok, thanks #{@bot.speaker.name}!"
                when 1 then "w00t! Let's get wasted!"
                when 2 then "Are you trying to get me fired?  Do you want me to boot you?!"
        cb = () => @bot.speak msg
        setTimeout cb, wait(1,3)
      @bot.upvote()

  drink_some_water: () =>
    if @bot.speaker.text.match(/.j subawater/)
      if @bot.toggles.grateful
        msg = switch rand() % 3
                when 0 then "I appreciate the gesture, but don't you have something a little stronger?"
                when 1 then "Thanks #{@bot.speaker.name}.  All those subasnacks were making me thirsty."
                when 2 then "It is a bit hot in here..."
        cb = () => @bot.speak msg
        setTimeout cb, wait(1,3)

  eat_a_subasnack: () =>
    if @bot.speaker.text.match(/\.j subasnack/)
      if @bot.toggles.grateful
        cb = () => @bot.speak "Thanks for the subasnack #{@bot.speaker.name}!"
        setTimeout cb, wait(1, 2)
      @bot.upvote()

  question_ones_makeup: () =>
    if @bot.toggles.chatty
      if @bot.speaker.text.match(/sub.* b(o|0)r?t/i) or @bot.speaker.text.match(/b(o|0)r?t.* suba/)
        msg = switch rand() % 5
                when 0 then 'No way!'
                when 1 then "Not that I'm aware of."
                when 2 then "Are you questioning my humanity?"
                when 3 then "That's a rude question!"
                when 4 then "What do you think?"
        cb = () => @bot.speak msg
        setTimeout cb, wait()

  time_to_dance: () =>
    match = (str for str in @bot.dance_matches when @bot.speaker.text.match str)
    if match.length
      @bot.upvote()

  what_are_the_rules: () =>
    if @bot.toggles.chatty
      if @bot.speaker.text.match(/^.j rules/)
        @bot.speak @bot.room_rules if @bot.room_rules


  ##  Be a bit talkative regarding our vote
  vote_commentary: () =>
    return false unless @bot.toggles.snarky
    switch rand(1,20) % 20
      when 1
        @bot.speak "This song is awesome!"
      when 2
        @bot.speak "Turtle bacon anyone?"
      when 3
        @bot.speak "Dancing is fun"
      when 4
        @bot.speak "Oooooh is this the Pearls Jams?"
      when 5
        @bot.speak "b0rT!!??"
      when 6
        @bot.speak "When can I play some music?"
      when 7
        @bot.speak ":fire:"
      when 8
        @bot.speak "/q please?"
      when 9
        @bot.speak "I like turtles!"
      when 10
        @bot.speak "I don't especially like this song, but you are awesome #{@bot.speaker.name}!"


#########################################################################
###   Room class
#################################################################################
class Room
  constructor: (data) ->
    @id          = null
    @description = null
    @name        = null
    @privacy     = null
    @snags       = 0
    @current_dj  = null
    @listeners   = null
    @dj_count    = null
    @max_djs     = null
    @moderators  = []
    @djs         = []
    @votelog     = []
    @users       = []
    @song = {
      id: null
      name: null
      artist: null
      album: null
      length: null
      genre: null
      coverart: null
      starttime: null
    }

    @votes = {
      up: 0
      down: 0
    }

    @dj = {
      name: null
      id: null
    }

    @dj = {
      name: null
      id: null
    }
    @update data if data

  downvotes: () -> @votes.down

  snags: () -> @snags

  update_votes: (data) ->
    data = data.room.metadata
    @votes.up = data.upvotes
    @votes.down = data.downvotes
    @votelog = data.votelog

  update: (data) ->
    return unless data
    room = data.room

    @id          = room.id ? room.roomid
    @description = room.description
    @name        = room.name
    @privacy     = room.privacy
    @snags       = room.snags ? 0

    if data.users
      @users = data.users

    if room.metadata
      @current_dj  = room.metadata.current_dj
      @listeners   = room.metadata.listeners
      @dj_count    = room.metadata.djcount
      @max_djs     = room.metadata.max_djs
      @moderators  = room.metadata.moderator_id
      @djs         = room.metadata.djs
      @votelog     = room.metadata.votelog

      song = room.metadata.current_song
      if song
        @song = {
          id: song._id
          name: song.metadata.song
          artist: song.metadata.artist
          album: song.metadata.album
          length: song.metadata.length
          genre: song.metadata.genre
          coverart: song.coverart
          starttime: song.starttime
        }
        @dj = {
          name: song.djname
          id: song.djid
        }

      @votes = {
        up: room.metadata.upvotes
        down: room.metadata.downvotes
      }

  upvotes: () -> @votes.up

  vote_percentage: () ->
    Math.round (@votes.up - @votes.down + @listeners) / (2 * @listeners) * 100


################################################################################
##    Speaker class
################################################################################
class Speaker
  name: null
  id: null
  text: null
  constructor: (@id, @name, @text) ->


################################################################################
##    PM class
################################################################################
class Pm
  senderid: null
  text: null
  time: null
  command: null
  arg: null
  extra_args: null

  constructor: (pm, @room, @bot) ->
    @senderid = pm.senderid
    @text = pm.text
    @time = pm.time
    if match = @text.match(/^\.(\S+) *(.*)/)
      @command = match[1]
      @arg = match[2]
      if match = @arg.match(/^(\S+) *(.*)/)
        @arg = match[1]
        @extra_args = match[2]

  decide: (callback) ->
    mod_ar = (mod for mod in @room.moderators when mod == @senderid) if @room and @room.moderators
    if @senderid == VDubsId or mod_ar.length
      callback(this)
    else
      @bot.pm "Sorry... I'm not allowed to talk to strangers!", @senderid

  respond: (msg) ->
    @bot.pm msg, @senderid


################################################################################
##    Moderate class
################################################################################
class Moderate
  constructor: (@bot) ->

  do: (pm) ->
    this[pm.command] pm

  ## Moderator Operations
  autodj: (data) -> @bot.autodj()
  dance: (data) -> @bot.upvote()
  dequeue: (data) ->
    @bot.playlistRemove 0
    data.respond "Removing song from queue"

  down: (data) ->
    @bot.dj_down()
    @bot.speak ":poop: :fire:"

  lame: (data) -> @bot.downvote()
  update_room_info: () -> @bot.update()

  obj: (data) ->
    #debug util.inspect @bot, true, null
    debug @bot[data.arg]()

  set: (data) ->
    what = data.arg
    to   = data.extra_args

    func = if @bot.toggles[what]? then () => @bot.toggle what else if this["set_#{what}"]? then () => this["set_#{what}"] to, data else () => @bot[what] = to
    func()
    msg = if to then "#{what} set to #{to}" else "#{what} set to #{@bot.toggles[what]}"
    data.respond msg
    debug msg

  set_avatar: (arg) -> @bot.setAvatar arg

  set_autodj: (arg) ->
    @bot.toggle 'autodj'
    @bot.toggle 'autobop'
    @bot.autodj()

  set_djannounce: (arg) -> @bot.djannounce = arg

  set_djgoodbye: (arg) -> @bot.djgoodbye = arg

  set_snag: (arg) -> @bot.snag = arg

  set_room: (arg, cb) ->
    id = if arg.length == 24 then arg else config.rooms[arg]
    unless id
      if cb
        return cb "I don't know about room #{arg}"
    @bot.roomRegister id

  show: (data) ->
    setting = @bot.toggles[data.arg] ? @bot[data.arg]
    data.respond "#{data.arg} == #{setting}"

  skip: (data) -> @bot.skip
  snag: (data) -> @bot.snag
  speak: (data) -> @bot.speak data.text

  up: (data) ->
    @bot.dj_up()
    @bot.speak "WooHoo!"


################################################################################
##    Operate class
################################################################################
class Operate
  constructor: (@bot) ->
    mod = new Moderate @bot

  do: (text) ->


################################################################################
##    Operate class
################################################################################
class UserManagement
  constructor: (@bot) ->


class DJQueue extends UserManagement

class FastestFingers extends UserManagement


################################################################################
##    Program
################################################################################


################################################################################
##
##                          EVENTS CALLBACKS
##
################################################################################

bot = new TTBot(AUTH, USERID, ROOM)
room = new Room

#bot.debug = true if config.debug
bot.on 'ready', () -> bot.roomRegister ROOM

#####  registered (when anyone enters the room)  ##### 
#bot.on 'registered', (data) -> bot.update { room: data }
#
######  roomChanged  ##### 
bot.on 'roomChanged', (data) ->
  bot.update {room: data}

#####  speak  ##### 
bot.on 'speak', (data) ->
  cb = ->
    bot.operate()
  bot.update {speaker: data}, cb

######  add_dj  ##### 
bot.on "add_dj", (data) -> bot.do_new_dj(data)

#####  rem_dj  ##### 
#bot.on "rem_dj", (data) ->
#  bot.autodj()
#  unless djgoodbye is "off"
#    bye = djgoodbye
#    bye = "Thanks for playing " + data.user[0].name + " :)"  unless bye
#    setTimeout (->
#      bot.speak bye
#    ), wait(1, 4)

#####  endsong  ##### 
bot.on "endsong", () ->
  bot.do_end_song()

#####  newsong  ##### 
bot.on "newsong", (data) -> bot.do_new_song(data)

#####  snagged  ##### 
bot.on "snagged", () -> bot.room.snags++

#####  pmmed  ##### 
bot.on 'pmmed', (pm) ->
  bot.update {pm: pm}, bot.do_pm_action

#####  update_votes  #####
bot.on 'update_votes', (data)-> bot.update_votes data
  
