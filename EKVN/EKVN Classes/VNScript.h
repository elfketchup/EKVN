//
//  VNScript.h
//
//  Created by James Briones on 7/3/11.
//  Copyright 2011. All rights reserved.
//

/*
 
 VNScript
 
 This converts a Property List (.plist) file into a "script" (stored in NSDictionary) for VNLayer to process.
 
 The property list should have at least one array in the root dictionary; each array is referred to be the script
 as a "conversation," and is made up of NSString objects that are either dialogue for characters or commands
 for the script to process. Most commands follow a syntax of:
 
   .command:PARAMETER1
 
   (or in the case of multiple parameters -> .command:PARAMETER1:PARAMETER2:(more parameters...)

 ...with varying numbers of parameters. There should be a colon between each parameter, and VNScript specifically
 checks for these colons to figure out how many parameters are in a command. Each command starts with a period character.
 If it doesn't, it's treated as a line of dialogue for a character to say.
 
 VNScript processes each NSString object in each array and converts it into smaller arrays made up of number objects
 or string objects. That data is later taken by VNLayer and processed and executed as commands.
 
 An important part of the script are the Indexes, which are used to keep track of which lines in the script needs processing.
 These are really just a sort of reference to which index in the current array (or "conversation") has been processed or should
 be processed.
 
 */


#import <Foundation/Foundation.h>

// Items inside of the script
#define VNScriptStartingPoint      @"start"
#define VNScriptActualScriptKey    @"actual script"

// Resource Dictionary
#define VNScriptVariablesKey       @"variables"
#define VNScriptSpritesArrayKey    @"sprites" // Stores filenames and sprite positions

// Flags for the script's dictionary. These are normally used for passing in dictionary values, and for when
// the script's data is saved to a dictionary (which can be stored as part of a save file... keep in mind
// that when the game is saved, all the game's data is stored in dictionaries).
#define VNScriptConversationNameKey            @"conversation name"
#define VNScriptFilenameKey                    @"filename"
#define VNScriptIndexesDoneKey                 @"indexes done"
#define VNScriptCurrentIndexKey                @"current index"

// The command types, in numeric format
#define VNScriptCommandSayLine                  100
#define VNScriptCommandAddSprite                101
#define VNScriptCommandSetBackground            102
#define VNScriptCommandSetSpeaker               103
#define VNScriptCommandChangeConversation       104
#define VNScriptCommandJumpOnChoice             105
#define VNScriptCommandShowSpeechOrNot          106
#define VNScriptCommandEffectFadeIn             107
#define VNScriptCommandEffectFadeOut            108
#define VNScriptCommandEffectMoveBackground     109
#define VNScriptCommandEffectMoveSprite         110
#define VNScriptCommandSetSpritePosition        111
#define VNScriptCommandPlaySound                112
#define VNScriptCommandPlayMusic                113
#define VNScriptCommandSetFlag                  114
#define VNScriptCommandModifyFlagValue          115 // Add or subtract
#define VNScriptCommandIfFlagHasValue           116 // An "if" command, really
#define VNScriptCommandModifyFlagOnChoice       117 // Choice changes variable
#define VNScriptCommandAlignSprite              118
#define VNScriptCommandRemoveSprite             119
#define VNScriptCommandJumpOnFlag               120 // Change conversation if a certain flag holds a particular value
#define VNScriptCommandSystemCall               121
//#define VNScriptCommandCallCode                 122 // CALLCODE has been disabled because it was a bad idea
#define VNScriptCommandIsFlagMoreThan           123
#define VNScriptCommandIsFlagLessThan           124
#define VNScriptCommandIsFlagBetween            125
#define VNScriptCommandSwitchScript             126
#define VNScriptCommandSetSpeechFont            127
#define VNScriptCommandSetSpeechFontSize        128
#define VNScriptCommandSetSpeakerFont           129
#define VNScriptCommandSetSpeakerFontSize       130
#define VNScriptCommandSetCinematicText         131
#define VNScriptCommandSetTypewriterText        132
#define VNScriptCommandSetSpeechbox             133
#define VNScriptCommandSetSpriteAlias           134
#define VNScriptCommandFlipSprite               135
#define VNScriptCommandRollDice                 136
#define VNScriptCommandModifyChoiceboxOffset    137
#define VNScriptCommandScaleBackground          138
#define VNScriptCommandScaleSprite              139
#define VNScriptCommandAddToChoiceSet           140
#define VNScriptCommandRemoveFromChoiceSet      141
#define VNScriptCommandWipeChoiceSet            142
#define VNScriptCommandShowChoiceSet            143
#define VNScriptCommandIsFlagLessThanFlag       144
#define VNScriptCommandIsFlagEqualToFlag        145
#define VNScriptCommandIsFlagMoreThanFlag       146
#define VNScriptCommandIncreaseFlagByFlag       147
#define VNScriptCommandDecreaseFlagByFlag       148
#define VNScriptCommandShowChoiceAndJump        149
#define VNScriptCommandShowChoiceAndModify      150

// The command strings. Each one starts with a dot (the parser will only check treat a line as a command if it starts
// with a dot), and is followed by some parameters, separated by colons.
#define VNScriptStringAddSprite                 @".addsprite"           // Adds a sprite to the screen (sprite fades in)
#define VNScriptStringSetBackground             @".setbackground"       // Changes the background of the visual novel scene
#define VNScriptStringSetSpeaker                @".setspeaker"          // Determines what name shows up when someone speaks
#define VNScriptStringChangeConversation        @".setconversation"     // Switches to a different section of the script
#define VNScriptStringJumpOnChoice              @".jumponchoice"        // Switches to different section based on user choice
#define VNScriptStringShowSpeechOrNot           @".showspeech"          // Determines whether speech text should be shown
#define VNScriptStringEffectFadeIn              @".fadein"              // Fades in the scene (background + characters)
#define VNScriptStringEffectFadeOut             @".fadeout"             // The scene fades out to black
#define VNScriptStringEffectMoveBackground      @".movebackground"      // Moves/pans the background
#define VNScriptStringEffectMoveSprite          @".movesprite"          // Moves a sprite around the screen
#define VNScriptStringSetSpritePosition         @".setspriteposition"   // Sets the sprite's exact position
#define VNScriptStringPlaySound                 @".playsound"           // Plays a sound effect once
#define VNScriptStringPlayMusic                 @".playmusic"           // Plays a sound file on infinite loop
#define VNScriptStringSetFlag                   @".setflag"             // Sets a "flag" (numeric value)
#define VNScriptStringModifyFlagValue           @".modifyflag"          // Modifies the numeric value of a flag
#define VNScriptStringIfFlagHasValue            @".isflag"              // Executes another command if a flag has a certain value
#define VNScriptStringModifyFlagOnChoice        @".modifyflagbychoice"  // Modifies a flag's value based on user input
#define VNScriptStringAlignSprite               @".alignsprite"         // Repositions a sprite (left, center, or right)
#define VNScriptStringRemoveSprite              @".removesprite"        // Removes a sprite from the screen
#define VNScriptStringJumpOnFlag                @".jumponflag"          // Changes script section based on flag value
#define VNScriptStringSystemCall                @".systemcall"          // Calls a predefined function outside the VN system
//#define VNScriptStringCallCode                  @".callcode"            // Call any function (from a static object, usually)
#define VNScriptStringIsFlagMoreThan            @".isflagmorethan"      // Runs another command if flag is more than a certain value
#define VNScriptStringIsFlagLessThan            @".isflaglessthan"      // Runs a command if a flag is LESS than a certain value
#define VNScriptStringIsFlagBetween             @".isflagbetween"       // Runs a command if a flag is between two values
#define VNScriptStringSwitchScript              @".switchscript"        // Changes to another VNScript (stored in a different .plist file)
#define VNScriptStringSetSpeechFont             @".setspeechfont"       // Changes speech font
#define VNScriptStringSetSpeechFontSize         @".setspeechfontsize"   // Changes speech font size
#define VNScriptStringSetSpeakerFont            @".setspeakerfont"      // Changes the font used by the speaker name
#define VNScriptStringSetSpeakerFontSize        @".setspeakerfontsize"  // Changes font size for speaker
#define VNScriptStringSetCinematicText          @".setcinematictext"    // "Cinematic text," where text/dialogue progresses without player input
#define VNScriptStringSetTypewriterText         @".settypewritertext"   // Typewriter text, in which dialogue appears one character at a time
#define VNScriptStringSetSpriteAlias            @".setspritealias"      // Assigns a filename to a sprite alias
#define VNScriptStringSetSpeechbox              @".setspeechbox"        // dynamically change speechbox sprite
#define VNScriptStringFlipSprite                @".flipsprite"          // flips sprite around (left/right or upside-down)
#define VNScriptStringRollDice                  @".rolldice"            // rolls dice, retrieves value and stores in flag
#define VNScriptStringModifyChoiceboxOffset     @".modifychoiceboxoffset" // adds X/Y offset to button coordinates during choices (default = 0,0)
#define VNScriptStringScaleBackground           @".scalebackground"     // changes background scale
#define VNScriptStringScaleSprite               @".scalesprite"         // changes sprite scale
#define VNScriptStringAddToChoiceSet            @".addtochoiceset"      // Adds a line of text choice and script section that it will jump to to a "choice set"
#define VNScriptStringRemoveFromChoiceSet       @".removefromchoiceset" // Removes a line of text / jump from a choice set
#define VNScriptStringWipeChoiceSet             @".wipechoiceset"       // Completely removes a Choice Set (this saves memory)
#define VNScriptStringShowChoiceSet             @".showchoiceset"       // Shows a series of choices from a set that can be dynamically modified
#define VNScriptStringIsFlagLessThanFlag        @".isflaglessthanflag"  // Runs a command if the first flag's value is lesser than the secon flag
#define VNScriptStringIsFlagEqualToFlag         @".isflagequaltoflag"   // Runs a command if the two flags have the same value
#define VNScriptStringIsFlagMoreThanFlag        @".isflagmorethanflag"  // Runs a command if the first flag's value is greater than the second flag
#define VNScriptStringIncreaseFlagByFlag        @".increaseflagbyflag"  // Increases flag by however much another flag's value is
#define VNScriptStringDecreaseFlagByFlag        @".decreaseflagbyflag"  // Subtracts the second flag's value from the first flag
#define VNScriptStringShowChoiceAndJump         @".showchoiceandjump"   // Shows a line of dialogue and then displays choice at the same time
#define VNScriptStringShowChoiceAndModify       @".showchoiceandmodify" // Shows a line of dialogue and then displays choice (for modifying flag)

// Script syntax
#define VNScriptSeparationString               @":"
#define VNScriptNilValue                       @"nil"

#pragma mark - VNScript

@interface VNScript : NSObject

#pragma mark - VNScript Properties

// Script data
@property (nonatomic, strong) NSDictionary* data; // Stores all the script data (dialogue, commands, etc)
@property (nonatomic, strong) NSArray* conversation; // Array that holds conversation script

// Conversation data
@property (nonatomic, strong) NSString* filename; // Where was the script loaded from?
@property (nonatomic, strong) NSString* conversationName; // The name of the current "conversation"

// Used for keeping track of the current indexes
@property NSInteger currentIndex;
@property NSInteger indexesDone;
@property NSInteger maxIndexes;
@property BOOL isFinished;

#pragma mark - VNScript Methods

// This gets the properties, which are the current "conversation"/section of the script, the script's filename,
// as well as the indexes used to figure out exactly which lines need processing.
- (NSDictionary*)info;

// The default initialization function; just pass in the script's filename and everything should work.
- (id)initFromFile:(NSString*)nameOfFile;
- (id)initFromFile:(NSString *)nameOfFile withConversation:(NSString*)conversationName;

// This version is used for loading the dictionary AND jumping to a particular part of the script.
- (id)initWithInfo:(NSDictionary*)dictionary;

// This converts the script from its default XML/Property-List format into a format that can be more easily
// understood and used by the VN system.
- (void)prepareScript:(NSDictionary*)dictionary;

- (id)currentCommand;
- (id)commandAtLine:(NSInteger)line;
- (BOOL)changeConversationTo:(NSString*)newConversation;
- (BOOL)lineShouldBeProcessed;
- (void)advanceLine;
- (void)advanceIndex;
- (id)analyzedCommand:(NSArray*)command; // This is where most of the processing work happens
- (id)currentLine;


@end
