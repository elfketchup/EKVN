//
//  VNScene.h
//
//  Created by James Briones on 7/3/11.
//  Copyright 2011. All rights reserved.
//

#import "cocos2d.h"
#import "VNScript.h"
#import "VNSystemCall.h"

/*
 
 VNScene
 
 VNScene is the main class for displaying and interacting with the Visual Novel system (or "VN system") I've coded.
 VNScene works by taking script data (interpreted from a Property List file using VNScript), and processes
 the script to handle audio and display graphics, text, and basic animation. It also handles user input for playing
 the scene and user choices, plus saving related data to EKRecord.
 
 Visual and audio elements are handled by VNScene; sprites and sounds are stored in a mutable dictionary and mutable array, 
 respectively. A record of the dialogue scene / visual-novel elements is kept by VNScene, and can be copied over to EKRecord 
 (and from EKRecord, into device memory) when necessary. During certain "volatile" periods (like when performing effects or
 presenting the player with a menu of choices), VNScene will store that record in a "safe save," which is created just before
 the effect/choice-menu is run, and holds the data from "the last time it was safe to save the game." Afterwards, when VNScene
 resumes "normal" activity, then the safe-save is removed and any attempts to save the game will just draw data from the
 "normal" record.
 
 When processing script data from VNScript, the script is divided into "conversations," which are really an NSArray
 of text/NSString objects that have been converted to string and number data to be more easily processed. Different "conversations"
 represent branching paths in the script. When VNScene begins processing script data, it always starts with a converation
 named "start".
 
 */

/*
 
 Coding/readability notes
 
 NOTE: What would become VNScene was originally written as part of a visual-novel game engine that I made in conjuction
       with a custom sprite-drawing kit written in OpenGL ES v1. At that time, it used the MVC (Model-View-Controller) model,
       where there were separate classes for each.
 
       Later, I ported the code over to Cocos2D (which worked MUCH better than my custom graphics kit), and the View and
       Controller classes were mixed together to form VNScene, while VNScript held the Model information. I've tried
       to clean up the code so it would make sense to reflect how things work now, but there are still some quirks and
       "leftovers" from the prior version of the code.
 
       Added January 2014: Also, upgrading to Cocos2D v3.0 caused some other changes to be made. VNScene used to be VNLayer,
       and inherited from CCLayer. Since that class has been removed, VNScene now inherits from CCScene. As some other
       Cocos2D classes have been renamed or had major changes, the classes in EKVN that relied on Cocos2D have had to change
       or be renamed alongside that. I've cleaned up the code somewhat, but it's possible that there are still some comments
       and other references to the "old" version of Cocos2D that I haven't spotted!

 */

#pragma mark - Defintions and Constants

#define VNSceneActivityType             @"VNScene" // The type of activity this is (used in conjuction with EKRecord)
#define VNSceneToPlayKey                @"scene to play"
#define VNSceneViewFontSize             17
#define VNSceneSpriteIsSafeToRemove     @"sprite is safe to remove" // Used for sprite removal (to free up memory and remove unused sprite)
#define VNScenePopSceneWhenDoneKey      @"pop scene when done" // Ask CCDirector to pop the  scene when the script finishes?

// Sprite alignment strings (used for commands)
#define VNSceneViewSpriteAlignmentLeftString                @"left"             // 25% of screen width
#define VNSceneViewSpriteAlignmentCenterString              @"center"           // 50% of screen width
#define VNSceneViewSpriteAlignmentRightString               @"right"            // 75% of screen width
#define VNSceneViewSpriteAlignemntFarLeftString             @"far left"         // 0% of screen width
#define VNSceneViewSpriteAlignmentExtremeLeftString         @"extreme left"     // -50% of screen width; offscreen to the left
#define VNSceneViewSpriteAlignmentFarRightString            @"far right"        // 100% of screen width
#define VNSceneViewSpriteAlignmentExtremeRightString        @"extreme right"    // 150% of screen width; offscreen to the right

// View settings keys
#define VNSceneViewTalkboxName                  @"talkbox.png"
#define VNSceneViewSpeechBoxOffsetFromBottomKey @"speechbox offset from bottom"
#define VNSceneViewSpriteTransitionSpeedKey     @"sprite transition speed"
#define VNSceneViewTextTransitionSpeedKey       @"text transition speed"
#define VNSceneViewNameTransitionSpeedKey       @"speaker name transition speed"
#define VNSceneViewSpeechBoxXKey                @"speech box x"
#define VNSceneViewSpeechBoxYKey                @"speech box y"
#define VNSceneViewNameXKey                     @"name x"
#define VNSceneViewNameYKey                     @"name y"
#define VNSceneViewSpeechXKey                   @"speech x"
#define VNSceneViewSpeechYKey                   @"speech y"
#define VNSceneViewSpriteXKey                   @"sprite x"
#define VNSceneViewSpriteYKey                   @"sprite y"
#define VNSceneViewButtonXKey                   @"button x"
#define VNSceneViewButtonYKey                   @"button y"
#define VNSceneViewSpeechHorizontalMarginsKey   @"speech horizontal margins"
#define VNSceneViewSpeechVerticalMarginsKey     @"speech vertical margins"
#define VNSceneViewSpeechBoxFilenameKey         @"speech box filename"
#define VNSceneViewSpeechOffsetXKey             @"speech offset x"
#define VNSceneViewSpeechOffsetYKey             @"speech offset y"
#define VNSceneViewDefaultBackgroundOpacityKey  @"default background opacity"
#define VNSceneViewMultiplyFontSizeForiPadKey   @"multiply font size for iPad"
#define VNSceneViewButtonUntouchedColorsKey     @"button untouched colors"
#define VNSceneViewButtonsTouchedColorsKey      @"button touched colors"

// Resource dictionary keys
#define VNSceneViewSpeechTextKey                @"speech text"
#define VNSceneViewSpeakerNameKey               @"speaker name"
#define VNSceneViewShowSpeechKey                @"show speech flag"
#define VNSceneViewBackgroundResourceKey        @"background resource"
#define VNSceneViewAudioInfoKey                 @"audio info"
#define VNSceneViewSpriteResourcesKey           @"sprite resources"
#define VNSceneViewSpriteNameKey                @"sprite name"
#define VNSceneViewSpriteAlphaKey               @"sprite alpha"
#define VNSceneViewSpriteXKey                   @"sprite x"
#define VNSceneViewSpriteYKey                   @"sprite y"
#define VNSceneViewSpeakerNameXOffsetKey        @"speaker name offset x"
#define VNSceneViewSpeakerNameYOffsetKey        @"speaker name offset y"
#define VNSceneViewButtonFilenameKey            @"button filename"
#define VNSceneViewFontSizeKey                  @"font size"
#define VNSceneViewFontNameKey                  @"font name"
#define VNSceneViewOverrideSpeechFontKey        @"override speech font from save"
#define VNSceneViewOverrideSpeechSizeKey        @"override speech size from save"
#define VNSceneViewOverrideSpeakerFontKey       @"override speaker font from save"
#define VNSceneViewOverrideSpeakerSizeKey       @"override speaker size from save"
#define VNSceneViewNoSkipUntilTextShownKey      @"no skipping until text is shown" // Prevents skipping until the text is fully shown

// Dictionary keys
#define VNSceneSavedScriptInfoKey               @"script info"
#define VNSceneSavedResourcesKey                @"saved resources"
#define VNSceneMusicToPlayKey                   @"music to play"
#define VNSceneMusicShouldLoopKey               @"music should loop"
#define VNSceneSpritesToShowKey                 @"sprites to show"
#define VNSceneSoundsToRemoveKey                @"sounds to remove"
#define VNSceneMusicToRemoveKey                 @"music to remove"
#define VNSceneBackgroundToShowKey              @"background to show"
#define VNSceneSpeakerNameToShowKey             @"speaker name to show"
#define VNSceneSpeechToDisplayKey               @"speech to display"
#define VNSceneShowSpeechKey                    @"show speech"
#define VNSceneBackgroundXKey                   @"background x"
#define VNSceneBackgroundYKey                   @"background y"
#define VNSceneCinematicTextSpeedKey            @"cinematic text speed"
#define VNSceneCinematicTextInputAllowedKey     @"cinematic text input allowed"
#define VNSceneTypewriterTextModeEnabledKey     @"typewriter text mode enabled"
#define VNSceneTypewriterSpeedInCharactersKey   @"typewriter speed in characters"
#define VNSceneTypewriterCanSkipTextKey         @"typewriter mode can skip text"

// UI "override" keys (used when you change things like font size/font name in the middle of a scene).
// By default, any changes will be restored when a saved game is loaded, though the "override X from save"
// settings can change this.
#define VNSceneOverrideSpeechFontKey    @"override speech font"
#define VNSceneOverrideSpeechSizeKey    @"override speech size"
#define VNSceneOverrideSpeakerFontKey   @"override speaker font"
#define VNSceneOverrideSpeakerSizeKey   @"override speaker size"

// Graphics/display stuff
#define VNSceneViewSettingsFileName     @"vnscene view settings"
#define VNSceneSpriteXKey               @"x position"
#define VNSceneSpriteYKey               @"y position"

// Sprite/node layers
#define VNSceneBackgroundLayer          50
#define VNSceneCharacterLayer           60
#define VNSceneUILayer                  100
#define VNSceneTextLayer                110
#define VNSceneButtonsLayer             120
#define VNSceneButtonTextLayer          130

// Node tags (NOTE: In Cocos2D v3.0, numeric tags were replaced with string-based names, similar to Sprite Kit)
#define VNSceneTagSpeechBox             @"speech box"   //600
#define VNSceneTagSpeakerName           @"speaker name" //601
#define VNSceneTagSpeechText            @"speech text"  //602
#define VNSceneTagBackground            @"background"   //603

// Scene modes
#define VNSceneModeLoading              100
#define VNSceneModeFinishedLoading      101
#define VNSceneModeNormal               200 // Normal "playing," with dialogue and interaction
#define VNSceneModeEffectIsRunning      201 // An Effect (fade-in/fade-out, sprite-movement, etc.) is currently running
#define VNSceneModeChoiceWithFlag       202
#define VNSceneModeChoiceWithJump       203
#define VNSceneModeEnded                300 // There isn't any more script data to process

#pragma mark - VNScene Declaration

@interface VNScene : CCScene {
    
    // Model data (which in this case is the scene's "script" that determines what will happen)
    VNScript* script;
    
    // A helper class that can be used to handle .systemcall commands. This may be redundant, now that
    // .callcode exists though!
    VNSystemCall* systemCallHelper;
    
    NSMutableDictionary* record; // Holds misc data (especially regarding the script)
    NSMutableDictionary* flags; // Local flags data (later saved to EKRecord's flags, when the scene is saved)
    
    int mode; // What the scene is doing (or should be doing) at the current moment
    
    // The "safe save" is an pseudo-autosave created right before performing a "dangerous" action like running an EKEffect.
    // Since saving the game in the middle of an effectt can cause unexpected results (like sprites being in the wrong
    // position), VNScene won't allow for anything to be saved until a "safe" point can be reached. Instead, VNScene saves
    // its data into this dictionary object beforehand, and if the user attempts to save the game in the middle of an effect,
    // they will only save the "safe" information instead of anything dangerous. Of course, when the "dangerous" part ends,
    // this dictionary is deleted, and things can be saved as normal.
    NSDictionary* safeSave;
    
    // View data
    NSMutableDictionary* viewSettings;
    
    BOOL effectIsRunning;
    BOOL isPlayingMusic;
    BOOL noSkippingUntilTextIsShown;
    
    NSMutableArray* soundsLoaded;
    NSMutableArray* buttons;
    NSMutableArray* choices; // Holds values that will be used when making choices
    NSMutableArray* choiceExtras; // Holds extra data that's used when making choices (usually, flag data)
    int buttonPicked; // Keeps track of the most recently touched button in the menu
    
    NSMutableDictionary* sprites;
    NSMutableArray* spritesToRemove;
    
    CCSprite* speechBox; // Dialogue box
    CCLabelTTF* speech;  // The text displayed as dialogue
    CCLabelTTF* speaker; // Name of speaker
    
    NSString* speechFont; // The name of the font used by the speech text
    NSString* speakerFont; // The name of the font used by the speaker text
    float fontSizeForSpeech;
    float fontSizeForSpeaker;
    
    float spriteTransitionSpeed, speechTransitionSpeed, speakerTransitionSpeed;
    ccColor3B buttonTouchedColors, buttonUntouchedColors;
    
    // Cinematic text
    double cinematicTextSpeed; // The speed at which text progresses without user input
    BOOL cinematicTextInputAllowed; // Whether or not user input can still be allowed
    int cinematicTextSpeedInFrames; // The speed in frames
    int cinematicTextCounter; // Used to keep track of current frames
    
    // Typewriter style text
    BOOL TWModeEnabled; // Off by default (standard EKVN text mode)
    BOOL TWCanSkip; // Can the user skip ahead (and cut the text short) by tapping?
    int TWSpeedInCharacters; // How many characters it should print per second
    int TWSpeedInFrames;
    int TWTimer; // Used to determine how many characters should be displayed (relative to the time/speed of displaying characters)
    double TWSpeedInSeconds;
    int TWNumberOfCurrentCharacters;
    int TWPreviousNumberOfCurrentChars;
    int TWNumberOfTotalCharacters;
    NSString* TWCurrentText; // What's currently on the screen
    NSString* TWFullText; // The entire line of text
}

//@property (nonatomic, strong) VNScript* script;
@property BOOL isFinished;
@property BOOL wasJustLoadedFromSave; // Useful because of some weird saving/loading quirks that popped up with .SYSTEMCALL:AUTOSAVE
@property BOOL popSceneWhenDone; // Determines whether VNScene should ask CCDirector to pop the top-most scene when the script finishes.

+ (VNScene*)currentVNScene;

+ (id)sceneWithSettings:(NSDictionary*)settings;
- (id)initWithSettings:(NSDictionary*)settings;

- (NSArray*)spriteDataFromScene; // Saves information about the sprites in the scene

- (void)loadDefaultViewSettings;
- (void)loadSavedResources;
- (void)loadUI;

- (void)removeUnusedSprites;
- (void)markActiveSpritesAsUnused;
- (void)purgeDataCreatedByScene; // Get rid of any objects that were allocated by the scene (but which may be stored ELSEWHERE)

- (void)runScript;
- (void)processCommand:(NSArray*)command;

- (void)setEffectRunningFlag;
- (void)clearEffectRunningFlag;

- (void)updateCinematicTextValues;
- (BOOL)cinematicTextAllowsUpdate; // Also returns YES if cinematic text is disabled

- (void)updateTypewriterTextValues; // Recalculates data (and whether or not to use typewriter speeds to begin with) (only called occasionally)
- (void)updateTypewriterTextLabels; // This handles the actual display of text (and this function can get called every frame)

- (void)updateScriptInfo;
- (void)createSafeSave;
- (void)removeSafeSave;
- (void)saveToRecord;

@end
