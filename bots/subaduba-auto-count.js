 * Automatically vote up on a song when 2 people say "bop"!
 * It's not against the turntable.fm policy to do so...
 * Reccomended for rooms with more people in it!
 */

var Bot    = equire('../index')
  , AUTH   = ''
  , USERID = ''
  , ROOMID = '';
var bot = new Bot(AUTH, USERID, ROOMID);

bopcount = 0;

bot.on('speak', function (data) {
   var text = data.text;

   // And when the bopcount reaches two...
   if (bopcount <= 1) {
     if (text.match(/dance/)) {
        bot.vote('up');
        bopcount += 1
     }
   }
});

/**
 * On/Off bot switch with basic variables in nodejs.
 */

// Define default value for global variable 'isOn'
var isOn = true;

bot.on('speak', function (data) {
   var name = data.name;
   var text = data.text;

   //If the bot is ON
   if (isOn) {
      if (text.match(/suba.+on/)) {
         bot.speak('You\'re getting me turned on baby! ;) :thumbsup:');
      }

      if (text.match(/suba.+off/)) {
         bot.speak('You\'re really turning me off you know! :poop:');
         // Set the status to off
         status = false;
      }

      //  ADD other functions here for when the bot is turned on. Like, for example:
      //  Respond to "/hello" command
//      if (text.match(/Hi|Hello|Hey .*sub/i)) {
//         bot.speak('Hey @'+name+'!  Wanna chat? :heart:');
//      }
   }

   //If the bot is OFF
   if (!isOn) {
      if (text.match(/how are you.* suba$/)) {
         bot.speak('I am really turned off');
      }

      if (text.match(/suba.+on/)) {
         bot.speak('I\' pretty turned on.');
         // Set the status to on
         status = true;
      }

      // ADD other functions here for when the bot is turned off.
   }
});

// Reset bopcount per new song
bot.on('newsong', function (data) {
   bopcount = 0;
});
