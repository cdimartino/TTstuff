/**
 * Automatically vote up on a song when 2 people say "bop"!
 * It's not against the turntable.fm policy to do so...
 * Reccomended for rooms with more people in it!
 */

var VDubsId= ''
var Bot    = require('../index')
  , AUTH   = ''
  , USERID = ''
  , ROOMID = '';
var bot = new Bot(AUTH, USERID, ROOMID);
//bot.debug = true;
var snag = 70;
var bopcount = 0;

// Define default value for global variable 'isOn'
var isOn = true;
var isChatty = false;
var isSnide = false;
var snagged = false;
//var isChatty = true;

/*
 *  Make him bop
 */
bot.on('speak', function (data) {
   var text = data.text;

   if (isOn) {
      if (text.match(/sub.* bot/i)) {
          setTimeout(function() { bot.speak("Hells no!!"); }, 2000);
      }
      if (text.match(/\.j subasnack/)) {
        bot.speak('That was tasty!');
      }
      if (text.match(/^@sub do you feel like talking?/i)) {
        if (isChatty == true) {
          bot.speak("Feeling pretty talkative!");
        }
        else {
          bot.speak("I don't feel like talking.");
        }
     }

     if (data.userid == VDubsId) {
       if (text.match(/^@sub be more chatty$/i)) {
         bot.speak(":)");
         isChatty = true;
         console.log('##### Chat mode enabled  #####')
       }

       if (text.match(/^@sub shutup!$/i)) {
         bot.speak(":(");
         isChatty = false;
         console.log('##### Chat mode disabled  #####')
       }
     }


//  Dont enable this without testing (privately).  It recurses //
/*
     if (text.match(/turtle/i) && data.userid != bot.USERID) {
      	//setTimeout(function() { bot.speak("I like turtles :)"); }, ((Math.random()*10) + 1) * 1000);
     }
*/

     if (text.match(/breakdance/i)) {
       if (((Math.random()*10)+1) % 3 == 0 ) { bot.speak("That headspin thingy?"); }
       if (data.userid == VDubsId) {
         if (text.match(/breakdance\!/i)) {
           bot.vote('down');
           bopcount -= 1;
         }
       }
     }
     else if ( ( text.match(/bop/i) || text.match(/dance/i) ) && bopcount == 0) {
        rand = Math.round(((Math.random()*10)+1));
        console.log('#### Bop on @ ' + rand + ' #####');
        setTimeout( function() {
          bot.vote('up');
          if (isSnide) {
            switch(rand) {
              case 1:
                bot.speak("This song is awesome!");
                break;
              case 3:
                //bot.speak("Dancing is fun");
                break;
              case 4:
                bot.speak("Oooooh is this the Pearls Jams?");
                break;
              case 7:
                //bot.speak(":fire:");
                break;
              case 9:
                bot.speak("I like turtles!");
                break;
            };
          }
        }, (((Math.random()*10)+1) * 1000));
        bopcount += 1;
     }
     if (text.match(/^@sub.+tired/i)) {
        setTimeout( function() { bot.speak("I need a nap!") }, Math.floor(Math.random()*10)+1);
     }
  }
});

bot.on('speak', function (data) {
   var text = data.text;

   //If the bot is ON
   console.log(data.userid + ' | ' + data.name + ": " + text);
   if ( data.userid == VDubsId ) {
      if (isOn) {
         if (text.match(/@sub.+(off|out)/i) || text.match(/(off|out).+@sub/i)) {
            bot.speak('o.O');
            // Set the status to off
            status = false;
            isOn = false
         }
      }
      else {
         if (text.match(/^@sub.+(up|on)/i) || text.match(/(on|up).+@sub/i)) {
            bot.speak('Chillin');
            isOn = true
         }
      }
    }
});

bot.on('update_votes', function (data) {
});

bot.on('endsong', function(data) {
  if (isOn == true) {

    room_data = data.room.metadata
    current_song = data.room.metadata.current_song
    percent = vote_percentage(room_data);

    if (percent >= snag) {
      bot.playlistAll( function(data) {
        bot.playlistAdd(current_song._id, data.list.length);
        console.log("\n#### Added song ####\n " + current_song.metadata.artist + ' // ' + current_song.metadata.song + " :: " + Math.round(percent) + "\n");
      });
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

bot.on('pmmed', function (data) { 
  text = data.text;
  console.log("#### Received PM: ####\n" + text);
  senderid = data.senderid
  if (senderid == VDubsId) {
    command = false;
    arg = false;
    match = text.match(/^\.(\S+) *(.*)/);
    if (match) {
      command = match[1];
      arg = match[2];
    }

    if (command) {
      switch (command) {
        case 'snag':
          snag = arg;
          message = "Changing snag threshold to: " + snag
          bot.pm(message, senderid);
          console.log(message, senderid);
          break;
        case 'snagsong':
          bot.snag();
          break;
        case 'speak':
          bot.speak(arg);
          break;
        case 'set':
          switch(arg) {
            case 'chatty':
              isChatty = !isChatty;
              bot.pm( "Chatty set to: " + isChatty, senderid );
              console.log( "Chatty set to: " + isChatty, senderid );
              break;
            case 'snide':
              isSnide = !isSnide;
              bot.pm( "Snide set to: " + isSnide, senderid );
              console.log( "Snide set to: " + isSnide, senderid );
              break;
            }
        case 'show':
          switch(arg) {
            case 'chatty':
              bot.pm(isChatty, senderid);
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
          }
          break;
      }
    }
  }
  else {
    console.log( "Sorry... I'm not allowed to talk to strangers!" );
  }
});

function vote_percentage(data) {
    return Math.round((data.upvotes - data.downvotes + data.listeners) / (2 * data.listeners) * 100)
}

function log(data) {

}
