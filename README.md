EKVN - ElfKetchup Visual Novel system
=====================================

EKVN is a framework, built on top of cocos2d-iphone, that can be used to create either
short dialogue scenes for games, or full-length "visual novel" games (or anything in between).
It has a simple "scripting language" for creating scenes, support for branching story paths,
built-in save game features, and a customizable user interface.

To start projects with EKVN, you'll need:

1. A Mac, running OS X 10.6 or newer
2. Xcode - http://developer.apple.com/xcode
3. cocos2d-iphone - http://www.cocos2d-iphone.org/

(And if you want to distribute games on the App Store, you'll also need to be a part of Apple's
iOS Developer Program! -> https://developer.apple.com/devcenter/ios/ )

Getting Started
===============

Most of this file consists of one long tutorial on how to get started using EKVN. If some of it seems
awfully basic, that's because it was written partly for people who didn't know much about Cocos2D / iOS,
but still wanted to make visual novels for iOS devices. More experienced/advanced developers may want
to skip the "simple" stuff and jump straight to the more complex ones; if that's the case, I would recommend
focusing more on Parts 3 and 5 of "Getting Started."

The file "EKVN commands list.txt" has a list of all the scripting language commands that can be used
by EKVN, and the source code (in the "EKVN Classes" folder) is fairly simple and well-commented, so anyone
who really wants to learn the ins and outs of EKVN should be able to do so easily (especially if they
already have experience with Cocos2D!)

The sample scripts ("demo script" and "test script") also show a lot of the scripting language and
its conventions in use. I would recommend playing around with them and changing certain values to
see what might happen.


Getting Started, Part 1: Starting a new project
-----------------------------------------------

(This assumes that you've downloaded the "EKVN test" project that has all the code and resource files 
that you'll need to get started, AND that you've installed the cocos2d-iphone project templates for Xcode)

1. Open up Xcode (I'm using version 5.0.2 )

2. Choose the "cocos2d iOS" template (under "iOS > cocos2d v3.x")

3. Name your project

4. Copy over the files/folders you need (for simplicity's sake, this would normally be the 
"EKVN Classes" and the "EKVN Resources" folder). Any files you don't need can be removed later.

5. Drag the folders from Finder into the project files list in Xcode. (I would leave the 
"Copy items into destination group's folder" option checked)

6. Open AppDelegate.m and replace the lines:
````
    #import "IntroScene.h"
    #import "HelloWorldScene.h"
````

with:
````
    #import "VNTestScene.h"
````

7. Scroll down to (or search for) the line that says
````
    return [IntroScene scene];
````
and replace it with:
````
    return [VNTestScene scene];
````
8. (Optional) Change the line that says:
````
    CCSetupShowDebugStats: @(YES),
````
to:
````
    CCSetupShowDebugStats: @(NO),
````
Unless, of course, you want to see how many frames-per-second the app is running at.

9. (Optional) Delete the following files from within Xcode:
````
HelloWorldScene.h
HelloWorldScene.m
IntroScene.h
IntroScene.m
NewtonConstants.h
NewtonScene.h
NewtonScene.m
NewtonSphere.h
NewtonSphere.m
LightBulb.h
LightBulb.m
Rope.h
Rope.m

fire.plist
fire.png
newton-ipadhd.plist
newton-ipadhd.png
newton-ipad.plist
newton-ipad.png
newton.plist
newton.png
````

10. (Optional) If you want to get rid of all the warnings that can pop up when you try to build/run
the app, you can go to "Project Settings > Build Phases > Compile Sources" and then select the following 
files:
````
VNScene.m
````

Select VNScene.m, hit Enter and type: -w

This will disable warnings for these files, which is very convenient (if potentially dangerous,
since it means that you won't be able to see if there are any obvious bugs or inconsistencies
in the code).


Getting Started, Part 2: Main Menu
----------------------------------

At this point, if you were to Build and then Run the project, you'll see the default Cocos2D
loading screen, and then the main menu for the test.

Now, if you just want to use EKVN for quick dialogue scenes, or you plan to code your own
heavily-customized menus, or just generally have no use for the default main menu, you can
just skip Part 2. On the other hand, if you're interested in using the default main menu,
then keep on reading. :)

The Main Menu is pretty simple (and a quick look at the source code would confirm this), but
it's also meant to be easy to customize. Most of the settings are stored in a file titled
"main_menu.plist" and you can open this up in Xcode and change the settings and see what
happens.

(NOTE: Keep in mind that the X and Y values for labels in the Main Menu don't store exact
pixel coordinates, but instead are used to position things in regards to the screen's width and height,
respectively... if that doesn't really make sense, just remember that setting X and Y to 0,0
will position something at the bottom-left corner of the screen, while setting X and Y to
1,1 will set it to the upper-right. Set it to anything lesser or greater than those values, and
the object will wind up pretty far offscreen!)

The three most important values in the Main Menu settings (and by "most important," I really mean
"the ones you're most likely to change!") are these:

1. background image
2. title image
3. script to load

The first one is pretty self-explanatory. If you want to create your own game, you should
supply your own background art. If you're not all that familiar with Cocos2D, you'll need
about two or four files for the background art, depending on whether or not you want to
support the iPad. For example, let's say you named your background image "backyard.png"
In that case, the files you'll need are:

````
backyard.png <- A 480x320 image, for the old iPhone
backyard-hd.png <- An 1136x640 image, for iPhone 4 and newer (1136px supports iPhone 5 also!)
backyard-ipad.png <- 1024x768 image for iPad 1 & 2, and iPad mini (first-gen)
backyard-ipadhd.png <- 2048x1536 image for iPad 3 and newer, and iPad mini 2 and newer
````

(NOTE: You'll need similar background images if you use the .SETBACKGROUND script command in EKVN,
though you can ignore the last two if your app doesn't support the iPad. Also, background can
really be of any sizes you like; EKVN doesn't enforce mandatory sizes. And if you plan to pan/move
the background, you should probably use larger images than the ones mentioned here.)

The SECOND value ("title image") is just a title or logo image. Similar to the background
images, you'll need two (or four, for the iPad), but there are no specific sizes required.
Keep in mind, however, that images for the iPhone 4 (and newer) and the iPad 1 & 2 will 
need to be twice as large as images for the old iPhone, and images for the iPad 3 and newer
will need to be FOUR TIMES as large as images for the old iPhone. For the sake of image
quality, I recommend creating the iPad 3+ images first, and then copying them and scaling
down the copies (you can do this in Preview, as well as most image editors).

The THIRD value ("script to load") determines which script file will be used by EKVN
when the player taps on "New Game." The default value is "demo script" but you should
change that to whatever your script is named (but don't include the ".plist" extension!)
For example, if you store your script in a file titled "hisao.plist" then you should
set the value of "script to load" to "hisao" ... oh, and unlike images, you don't
need multiple versions of the same script for different devices. :)


Getting Started, Part 3: The Scripting Language
-----------------------------------------------

The "scripts" are stored in what Xcode calls "Property List" files (extension ".plist").
Each script is divided into sections (or "conversations," which in retrospect doesn't
really make that much sense). The sections are Array objects, and each array holds a number
of string objects, which make up the individual lines and commands of the "scripting language."

To start a new script, just create a property list file, click on the "Root" and hit Enter.
You'll have a String object called "New item." Change this from a String to an Array,
and title it "start" (without quotes, of course). You've now made your first "section" of the
script. Remember that every script needs to have a section titled "start," since EKVN
specifically looks for this section (and starts here, no pun intended).

Now that you have a section, click on the triangle symbol that's at the left of the section's
name, then hit Enter. A new string object will be added to the section. Whenever you click on
a string and hit Enter, a new string will be inserted into the Array right below it (this is
a good way to insert new commands between existing commands in the script).

In this first line, type "Hello." (or whatever witty thing you can think to say). If you were
to run this script right now, you would get a blank background, the and a dialogue box saying
"Hello." As soon as you tap on the screen, however, the scene would end and you'd be back at
the Main Menu.

A good -- if not very exciting -- start. You could enter more lines, each filled with witty
lines of dialogue, but as you've probably guessed, the background would never change, no
characters would appear onscreen, and there wouldn't be much interaction going on.

This is where the scripting language's commands come in. Each command starts with a dot (".")
and the command and its parameters are separated by the colon (":") character. The template is
````
.(COMMAND NAME):(parameter #1):(possibly more parameters...?)
````
(For reference, the commands given in the guide are all in UPPERCASE, so that it's easier to
tell which is a command, and which is not. However, commands in EKVN are not case-sensitive. You
could use ".setbackground" just as easily as ".SETBACKGROUND"

That said, files are ALWAYS case-sensitive in EKVN. Using ".SETBACKGROUND:Pond.png" is very different
from using ".SETBACKGROUND:pond.png" at least as far as EKVN is concerned. It might work when
running in the Simulator, but it will have very different results on an actual iOS device!)

Now, back to the script you're writing. Try entering:
````
.SETBACKGROUND:pond.png
````
Run it, and then... nothing really happens? Actually, something DID happen, except that
the scene immediately ended afterwards, so it wasn't noticeable. Add the following line:
````
Hey, a background!
````
Now, your new scene will point out the obvious before returning to the main menu. Still,
there's not much going on, and a visual novel about changing backgrounds is probably not
going to be overwhelmingly popular. So, here are a few more lines you can add (in this order):
````
.ADDSPRITE:matsuri_close.png

Suddenly, an anime girl appears!

.SETSPEAKER:Matsuri

Hi, my name is Matsuri.

.SETSPEAKER:nil

You've now met your first character.

.PLAYMUSIC:music01.mp3

.ALIGNSPRITE:matsuri_close.png:left

.ALIGNSPRITE:matsuri_close.png:right

.ALIGNSPRITE:matsuri_close.png:center

Is she... dancing?

.PLAYMUSIC:nil

.REMOVESPRITE:matsuri_close.png

The music stops, and the girl disappears.

That wasn't strange at all.
````
Now, after you've entered those lines, try building and running the game. You should experience
a strange (but working!) scene, especially if you've imported all of the files from EKVN test.
(if you didn't, the app would have crashed since it would be missing some of the art / audio
files).

Most games do feature things like diverging story branches, multiple endings, etc. EKVN scripts
can hold multiple sections (or "Arrays," if you prefer), which represent the branching paths
of a story (or script, in this case). Click on the "Root" object in the script, and then hit
Enter. A String object titled "New item" appears, change it to an Array object named "color", and
then click the triangle and add the following lines:
````
.ADDSPRITE:matsuri_close.png

Matsuri reappears, in color again!
````
Now click on the Root, but this time create an Array titled "sketch" with the following lines:
````
.ADDSPRITE:sketchmatsuri_close.png

Matsuri reappears, but now she just looks like a sketch of an anime girl.
````
Go back to the "start" section, and at the end (after the line "That wasn't strange at all."),
add the following lines:
````
.SYSTEMCALL:autosave

Would you prefer Matsuri to have color, or not?

.JUMPONCHOICE:"She should have color":color:No color is better:sketch
````
Now, when you run the app, you'll be presented with a choice, and can choose which version
of Matsuri to see. If you press on the button "She should have color" then EKVN will switch
over to the "color" section. On the other hand, if you choose "No color is better," then
the story branches into the "sketch" section. (Also, you can add more choices with more sections,
as the .JUMPONCHOICE command isn't limited to just two choices.)

Also! You may be wondering what that ".SYSTEMCALL:autosave" part is for. After you run the game
(and get kicked back out into the Main Menu), you can now tap on "Continue" and a saved game
will load, taking you back to just before you made your choice. Using the .SYSTEMCALL:autosave
command before making important choices can be a good practice for your own games.

Finally (in case this guide isn't long enough!), EKVN also comes with a "Flags" feature,
which can also be used for diverging story branches. Delete the last line (with .JUMPONCHOICE)
and replace it with the following
````
.SETFLAG:matsuri_color:0

.MODIFYFLAGBYCHOICE:"She should have color":matsuri_color:1:No color is better:matsuri_color:0

Well, you've made your choice.

.ISFLAG:matsuri_color:1:You like the full-color version better, huh?

.ISFLAG:matsuri_color:0:You like the non-colored version better?

.ISFLAG:matsuri_color:1:.SETCONVERSATION:color

.SETCONVERSATION:sketch
````
Run your scene again, and you'll what happens: MOSTLY the same thing as last time! Now, you might
be thinking "this latest version is actually more work! Why would I want to do it this way? The earlier
version was easier!"

In this example, yes, using Flags IS more work. But in a longer, more complex game, it might not
be. If you had to jump to a different section each and every time the player made a choice (even
really mundane choices), your game (and the accompanying script) could get very complicated in a 
hurry. If, on the other hand, you used flags, you could just modify a flag here or there, and
then with a few extra lines, the game would respond differently, without constantly jumping
to different sections and dealing with the hassle of keeping track of all the branching paths.

Oh, and one more thing. You can change the last .ISFLAG command from
````
.ISFLAG:matsuri_color:1:.SETCONVERSATION:color

into:

.JUMPONFLAG:matsuri_color:1:color
````
This is a simpler way to change sections/conversations based on the values of certain flags.
Also, another thing to keep in mind: All flags, when created, start with a value of ZERO, and 
can be manually SET to a specific value by .SETFLAG, or MODIFIED by a particular value by 
.MODIFYFLAG (and its user-interactive equivalent, .MODIFYFLAGBYCHOICE).

And that's it for the scripting language! You now know enough commands to create a fairly complex
visual novel. Of course, you're probably wondering exactly how the scripting language commands
should work (and just how many there may be). The full list of commands is written down in the
"EKVN commands list.txt" file, along with a few short examples of how to use them.


Getting Started, Part 4: Customization
--------------------------------------

It's very possible that you don't like the default "look" of the EKVN user interface. The files
that determine most of how the EKVN looks to the player are stored i the "UI Files" folder,
and include the Property List files for the main menu ("main_menu.plist") and for the "main" UI
that appears for everything else (stored in "VNScene view settings.plist"). The latter allows
you to change things like fonts, margins/offsets, text sizes, etc. (If a particular value seems
mysterious, try changing it around and seeing what happens... you may get interesting results!)

You can also completely change the look of the speech/dialogue-boxes and menu buttons just
by overwriting the "choicebox" and "talkbox" image files stored in the UI Files folder. For example,
let's say you want to change the look of the speech-boxes where dialogue pops up. The simplest
way is to just overwrite "talkbox.png" (and its higher-resolution counterparts). The names
and sizes for the "talkbox.png" are:
````
talkbox.png <- iPhone 3GS version, 480x120
talkbox-hd.png <- iPhone 4 and newer, 1136x240
talkbox-ipad.png <- iPad 1 & 2 and iPad Mini (first generation), 1024x170
talkbox-ipadhd.png <- iPad 3 and newer, iPad Mini 2 and newer, 2048x340
````
(NOTE: Because the iPad has a much wider screen, the UI files for them are wider, but also shorter in height)

If you overwrite them with images that use differents sizes (say you replace talkbox.png with
an image that's 480x200, or 320x100), you MIGHT need to change the values in the file
"VNScene view settings.plist" so that the text displays properly. Normally, EKVN tries to 
calculate where and how text should be laid out, though there's no guarantee that the 
auto-generated values will look good. In that case, tweaking the view settings' values
should be enough to get it looking good. In the most extreme scenario, you may need to
change the UI code yourself to get things to look exactly how you want to.

Getting Started, Part 5: Coding
-------------------------------

It's entirely possible to create a working visual novel using just the first three or four "Getting Started"
steps, but if you really want to get the most out of EKVN, and do things like extend or modify the existing
functionality (or outright add new features), you'll have to do some programming. Most of the code
is fairly well-commented, so it should be easy enough to figure out how things work.

Of course, you may not want to rely on the rather simplistic "main menu" code I wrote and/or you just
want to integrate some of EKVN's features into existing code. This section explains some of how to do that.

If you want to run EKVN (or at least, its "central" class, VNScene) on its own, the simplest way is
to do something like this:
````
NSString* nameOfScriptFile = @"my script"; // Leave out the .plist extension!
NSDictionary* settingsForScene = @{ VNSceneToPlayKey: nameOfScriptFile };
[[CCDirector sharedDirector] pushScene:[VNScene sceneWithSettings:settingsForScene]];
````
This creates an entirely new VNScene object, and has it runs as the top-level Cocos2D scene,
with a particular script.

(NOTE: It's also possible to just add VNScene as a child node to an existing CCScene, but this
is something that could potentially get messy, so I don't recommend it unless you're
already at least somewhat experienced with Cocos2D).

Of course, this is only for starting new games. EKVN stores its own saved game data using a
class called EKRecord, which in turn stores its data in NSUserDefaults. To load a saved EKVN game,
you can just do something like this:
````
if( [[EKRecord sharedRecord] hasAnySavedData] == YES ) {

NSDictionary* activityRecords = [[EKRecord sharedRecord] activityDict];
NSDictionary* savedData = [activityRecords objectForKey:EKRecordActivityDataKey];
[[CCDirector sharedDirector] pushScene:[VNScene sceneWithSettings:savedData]];
}
````
If EKVN has any saved data, then it will reload a previously-saved game, along with whatever
text / sprites / audio / etc. it had when the game was saved.


Getting Started, Part 6: The App Store
--------------------------------------

While running the app on the Simulator is nice, chances are that you'll want to actually have
your own games on the App Store. For that, you'll need to be a part of Apple's iOS Developer
Program. That, however, is a much longer and complex topic than anything I've written about here,
so you'll have to go their site to learn more about it. As far as publishing to the App Store,
and actually getting people to download and play your game, all I can is... GOOD LUCK!

And Apple's developer site is here: http://developer.apple.com


MIT License
===========

EKVN is released under the MIT License

Copyright (c) 2011-2013 James Briones

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
