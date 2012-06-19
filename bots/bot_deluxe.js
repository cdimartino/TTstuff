/**
 * Automatically vote up on a song when 2 people say "bop"!
 * It's not against the turntable.fm policy to do so...
 * Reccomended for rooms with more people in it!
 */

var config = require('../config.json');
var VDubsId = config.userids.vdubs;
var Bot    = require('../index')
  , AUTH   = config.auths[process.argv[2]]
  , USERID = config.userids[process.argv[2]]
  , ROOMID = process.argv[3] != false ? config.rooms[process.argv[3]] : config.rooms.vdubs;
var bot = new Bot(AUTH, USERID, ROOMID);
var snag = false;
var bopcount = 0;

// Define default value for global variable 'isOn'
var isOn = true;
var isChatty = false;
var isSnide = false;
var snagged = false;
var autodj = false;
var autobop = false;
var isFriendly = false;
var isGrateful = false;
var djannounce = 'off';
var djgoodbye = 'off';

/*
 *  Make him bop
 */
bot.on('speak', function (data) {
   var text = data.text;

   if (isOn) {
      if (text.match(/sub.* bot/i)) {
          setTimeout(function() { bot.speak("Hells no!!"); }, wait());
      }
      if (text.match(/\.j subasnack/)) {
        if (isGrateful) {
          setTimeout(function() { bot.speak("Thanks for the subasnack " + data.name + "!"); }, wait(1,2));

          time = wait(3,6);
          num = rand(1,10);
          switch (num % 3)  {
            case 0:
              setTimeout(function() { bot.speak("Hey JSBot, have a snack courtesy of " + data.name + " and me!"); bot.speak(".j botsnack"); }, time);
              break;
            case 1:
              setTimeout(function() { bot.speak("mmm... That was tasty!"); }, time);
              break;
            }
        }
        upvote(false);
      }

      if (text.match(/\.j botsnack/)) {
        if (isGrateful) {
          if (rand() % 4 == 0) {
            setTimeout(function() { bot.speak('Can I have a subasnack too please?');}, 1000);
          }
        }
      }

      if (text.match(/.j subawater/)) {
        if (isGrateful) {
          if (rand() % 2 == 0) {
            setTimeout(function() { bot.speak("I appreciate the gesture, but don't you have something a little stronger?");}, wait(1,3));
          }
          else {
            setTimeout(function() { bot.speak("Thanks " + data.name + ".  All those subasnacks were making me thirsty.");}, wait(1,3));
          }
        }
        upvote(false);
      }

      if (text.match(/.j refreshing *(bud|hein|coor|coron|beer|glass of milk|cup of urine)/)) {
        if (isGrateful) {
          if (rand() % 2 == 0) {
            setTimeout(function() { bot.speak("I don't usually drink on the job... but ok, thanks " + data.name + "!");}, wait(1,3));
          }
          else {
            setTimeout(function() { bot.speak("w00t! Let's get wasted!");}, wait(1,3));
          }
        }
        upvote(false);
      }

      if (!autodj) {
        if (text.match(/breakdance/i)) {
          if (((Math.random()*10)+1) % 3 == 0 ) { bot.speak("That headspin thingy?"); }
          if (data.userid == VDubsId) {
            if (text.match(/breakdance\!/i)) {
              bot.vote('down');
              bopcount -= 1;
            }
          }
        }
        else if ( text.match(/danc|bop|boogie|mosh/i) && bopcount <= 0) {
          upvote(isSnide);
        }
      }
   }
   console.log(text);
});

doautodj = function(data) {
  if ( autodj == false ) {
    return;
  }

  bot.roomInfo(false, function(data) {
    var im_a_dj = data.room.metadata.djs.indexOf(bot.userId) != -1 ? true : false;
    var threshold = data.room.metadata.max_djs - 1;
    if (im_a_dj) {
      if ( data.room.metadata.djcount > threshold ) {
        if ( data.room.metadata.current_dj == bot.userId ) {
          bot.speak("Turtles after this song!");
          bot.on('endsong', djDown);
        }
        else {
          console.log("####  Too many djs.  Getting down. ####");
          bot.speak("Who likes turtles?");
          setTimeout(djDown, wait());
        }
      }
    }
    else if (data.room.metadata.djcount < threshold) {
      console.log("#####  I'm getting up: " + data.room.metadata.djcount + " < " + threshold + "  ####");
      setTimeout(bot.speak("Looks like there's room for me!  w00t!"), wait());
      bot.addDj();
    }
    else {
      console.log("####  Not doing anything: " + data.room.metadata.djcount + " of " + data.room.metadata.max_djs + " spots taken");
    }
  });
}

bot.on('add_dj', doautodj);
bot.on('rem_dj', doautodj);
bot.on('endsong', doautodj);

// greet the new peeps
bot.on('add_dj', function(data) {
  if (djannounce != 'off') {
    announce = djannounce;
    if (!announce) {
      announce = "Hi " + data.user[0].name +".  Enjoy your time on stage.  Respect the other djs!";
    }
    setTimeout(function() { bot.speak(announce); }, wait(1,4));
  }
});

// Say goodbye too!
bot.on('rem_dj', function(data) {
  if (djgoodbye != 'off') {
    bye = djgoodbye;
    if (!bye) {
      bye = "Thanks for playing " + data.user[0].name + " :)";
    }
    setTimeout(function() { bot.speak(bye);}, wait(1,4));
  }
});

bot.on('endsong', function(data) {
  if (!data) { return };
  if (! data.room ) { return };
  if (isOn == true) {
    room_data = data.room.metadata
    current_song = data.room.metadata.current_song

    if (!current_song) { return };

    percent = vote_percentage(room_data);

    if ( snag != false ) {
      if (percent >= snag) {
        bot.playlistAll( function(data) {
          bot.playlistAdd(current_song._id, data.list.length);
          console.log("\n#### Added song ####\n " + current_song.metadata.artist + ' // ' + current_song.metadata.song + " :: " + Math.round(percent) + "\n");
        });
      }
    }

    if (isChatty) {
      console.log("\n#### Speaking song stats ####");
      bot.speak(current_song.metadata.artist + "  ::  " + current_song.metadata.song +
                 " Received  -  Ups: " + room_data.upvotes +
                 "  |  Downs: " + room_data.downvotes +
                 "  -  That's a " + Math.round(percent) +  "% room rating");
    }
    else {
      console.log("\n#### Logging song stats ####");
      console.log(current_song.metadata.artist + "  ::  " + current_song.metadata.song +
                 " -  Ups: " + room_data.upvotes +
                 "  |  Downs: " + room_data.downvotes +
                 "  -  " + Math.round(percent) +  "% room rating");
    }
  }
  snagged = false;
  bopcount = 0;
});

//  If we stepped down while autodjing this will be set, so unset it.
bot.on('newsong', function() { bot.removeListener('endsong', djDown) });

bot.on('pmmed', function (data) { 
  text = data.text;
  console.log("#### Received PM: ####\n" + text);
  senderid = data.senderid
  if (senderid == VDubsId) {
    command = false;
    arg = false;
    extra_args = false;

    match = text.match(/^\.(\S+) *(.*)/);
    if (match) {
      command = match[1];
      arg = match[2];
      if (command != 'speak' && match[2]) {
        match = arg.match(/^(\S+) *(.*)/);
        arg = match[1];
        extra_args = match[2];
      }
    }

    if (command) {
      switch (command) {
        case 'snag':
          bot.snag();
          break;
        case 'speak':
          bot.speak(arg);
          break;
        case 'auto':
          doautodj();
          break;
        case 'up':
          bot.addDj();
          bot.speak("WooHoo!")
          break;
        case 'down':
          djDown();
          bot.speak(":poop: :fire:");
          break;
        case 'dance':
          bopcount = 0;
          upvote(false);
          break;
        case 'lame':
          bot.vote('down');
          break;
        case 'skip':
          bot.skip();
          bot.pm("Skipping song", senderid);
          break;
        case 'dequeue':
          bot.playlistRemove(0);
          bot.pm("Removing song from queue", senderid);
          break;
        case 'set':
          switch(arg) {
            case 'avatar':
              bot.setAvatar(extra_args);
              bot.pm("Set avatar to: " + extra_args, senderid);
              break;
            case 'friendly':
              isFriendly = !isFriendly;
              bot.pm( "Friendly set to: " + isFriendly, senderid );
              console.log( "Friendly set to: " + isFriendly );
              break;
            case 'chatty':
              isChatty = !isChatty;
              bot.pm( "Chatty set to: " + isChatty, senderid );
              console.log( "Chatty set to: " + isChatty);
              break;
            case 'grateful':
              isGrateful = !isGrateful;
              bot.pm( "Grateful set to: " + isGrateful, senderid );
              console.log( "Grateful set to: " + isGrateful);
              break;
            case 'snide':
              isSnide = !isSnide;
              bot.pm( "Snide set to: " + isSnide, senderid );
              console.log( "Snide set to: " + isSnide);
              break;
            case 'autodj':
              autodj = !autodj;
              autobop = autodj;
              bot.pm("Autodj set to: " + autodj, senderid);
              bot.pm("Autobop set to: " + autobop, senderid);
              console.log( "Autodj set to: " + autodj);
              doautodj();
              doAutoBop(autobop);
              break;
            case 'djannounce':
              djannounce = extra_args;
              message = "Changing DJ Announce to: " + djannounce;
              bot.pm(message, senderid);
              console.log(message);
              break;
            case 'djgoodbye':
              djgoodbye = extra_args;
              message = "Changing DJ Goodbye to: " + djannounce;
              bot.pm(message, senderid);
              console.log(message);
              break;
            case 'snag':
              snag = extra_args;
              message = "Changing snag threshold to: " + snag;
              bot.pm(message, senderid);
              console.log(message);
              break;
            case 'snag':
              snag = extra_args;
              message = "Changing snag threshold to: " + snag;
              bot.pm(message, senderid);
              console.log(message);
              break;
            case 'room':
              room = extra_args;
              if ( room.length == 24 ) {
                id = room;
              }
              else {
                id = config.rooms[room];
              }
              if ( ! id ) {
                bot.pm("I dont know about room " + room, senderid);
                break;
              }
              message = "Moving over to: " + room + ": " + id;
              bot.pm(message, senderid);
              console.log(message);
              bot.roomRegister(id);
              break;
            case 'autobop':
              autobop = !autobop;
              doAutoBop(autobop);
              break;
            }
        case 'show':
          switch(arg) {
            case 'chatty':
              bot.pm(isChatty, senderid);
              break;
            case 'djannounce':
              bot.pm(djannounce, senderid);
              break;
            case 'djgoodbye':
              bot.pm(djgoodbye, senderid);
              break;
            case 'grateful':
              bot.pm(isGrateful, senderid);
              break;
            case 'friendly':
              bot.pm(isFriendly, senderid);
              break;
            case 'queue':
              bot.playlistAll(function(data) { console.log(data); });
              break;
            case 'fans':
              bot.getFans(function(data) { console.log( data); });
              break;
            case 'snag':
              bot.pm( "Snag @ " + snag, senderid );
              break;
            case 'snide':
              bot.pm( "Snide @ " + isSnide, senderid );
              break;
            case 'autodj':
              bot.pm( "Autodj @ " + autodj, senderid );
              break;
            case 'autobop':
              bot.pm( "Autobop @ " + autobop, senderid );
              break;
            case 'rooms':
              for ( room in config.rooms ) {
                bot.pm(room,senderid);
              }
              break;
          }
          break;
      }
    }
  }
  else {
    bot.pm( "Sorry... I'm not allowed to talk to strangers!", senderid );
  }
});

function vote_percentage(data) {
  return Math.round((data.upvotes - data.downvotes + data.listeners) / (2 * data.listeners) * 100)
}

function rand(min, max) {
  if (!min) { min = 1 };
  if (!max) { max = 6 };
  return Math.floor(Math.random() * (max - min + 1) + min);
}

function wait(min, max) {
  if (!min) { min = 1 };
  if (!max) { max = 6 };
  return rand(min, max) * 1000;
}

function upvote(snarky) {
  if (bopcount > 0) { return false };
  time = wait();
  console.log('#### Bop on @ ' + time/1000 + ' count: ' + bopcount + ' #####');
  setTimeout( function(snarky) {
    bot.vote('up', checkvoteCB);
    if (snarky) {
      switch(time/1000) {
        case 1:
          bot.speak("This song is awesome!");
          break;
        case 2:
          bot.speak("Turtle bacon anyone?");
          break;
        case 3:
          bot.speak("Dancing is fun");
          break;
        case 4:
          bot.speak("Oooooh is this the Pearls Jams?");
          break;
        case 5:
          bot.speak("b0rT!!??");
          break;
        case 6:
          bot.speak("When can I play some music?");
          break;
        case 7:
          bot.speak(":fire:");
          break;
        case 8:
          bot.speak("/q please?");
          break;
        case 9:
          bot.speak("I like turtles!");
          break;
      };
    }
  }, time);
}

var checkvoteCB = function(data) {
  console.log(data);
  if (data.success) {
    bopcount += 1;
  } else if (data.err != "Cannot vote on your song" && data.err != "User has already voted up") {
    bopcount = 0;
    console.log("Retrying vote");
    upvote(false);
  }
}

function doAutoBop(doit) {
  console.log("#### Setting Autobop to: " + doit + " ####");
  vote = function() { setTimeout(upvote, 3000, [false]); };
  if (doit) {
    bot.on('newsong', vote);
  }
  else {
    bot.removeListener('newsong', vote);
  }
}

function log(msg) {
  if (logging) {
    console.log(msg);
  }
}

djDown = function() {
  bot.remDj(USERID);
}
