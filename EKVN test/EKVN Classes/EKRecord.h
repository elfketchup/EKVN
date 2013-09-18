//
//  EKRecord.h
//
//  Created by James Briones on 2/5/11.
//  Copyright 2011. All rights reserved.
//

/*
 
 EKRecord
 
 This class works by storing game data in NSUserDefaults. There are two types of data; the "global" data
 that remains the same across all saved games / new games, and then the data that's stored inside "slots"
 and is only relevant within a particular playthrough of the game.
 
 The "global" relevant-across-all-playthroughs data is just stored in NSUserDefault's "root" dictionary
 as either NSString or NSNumber objects. Conversely, an entire slot is stored as a single NSData object
 in the root dictionary. Each slot can be accessed through the dictionary key "slotX", where X is the
 number.
 
 The main Global values are:
   1. HIGH SCORE (NSUInteger) - The highest score achieved by a player
   2. DATE SAVED (NSDate object) - Time and date of most recent saved game
   3. CURRENT SLOT (NSUInteger) - Which save slot was most recently used
 
 Slot Zero ("slot0") is the default slot, and is meant mostly for autosave data. If you're creating a game
 where it's not necessary to have multiple slots/games/playthroughs, then you can just store everything
 in Slot Zero. On the other hand, some other game types (such as, say, JRPGs) might require multiple slots.
 There is no hard-coded limit on the number of slots you can use.

 Each slot is an NSData object, which can be decoded into a single NSDictionary (or more practically,
 an NSMutableDictionary) called the Record, which holds the following values:
 
   1. ACTIVITY TYPE (NSString) - What kind of activity the player was engaged in when the game was saved
                                 (a specific mini-game, cutscene, etc)
   2. ACTIVITY DICTIONARY (NSDictionary) - Stores information specific to that activity (sprite positions, score, etc)
   3. FLAG DATA (NSDictionary) - A dictionary of flags (each flag is a key that corresponds to an int value)
 
 An Activity is a particular task/mini-game that the player is involved with. This could be a particular level
 in the game, a dialogue/cutscene sequence, a mini-game, traversing a map of the world, etc. The Activity Dictionary
 holds information specific to an Activity type, such as mini-game scores, locations of sprites, level data, etc.
 When the game is saved, the player's current Activity should save any relevant data, and when the game is loaded,
 that same data is supposed to recreate the Activity exactly as the player left it (or something close enough
 that the player shouldn't complain too much!)
 
 Flags are information not specific to a particular activity, but can instead be used throughout a particular
 playthrough of the game. For example, relationships scores in regards to other characters, progress through
 a story, experience points and money, etc. In theory, as long as anything can be stored as an integer value
 and is used throughout the playthrough, it can be stored as a flag. (It's also possible to store flags with
 non-integer data, but ints are the standard value type... nevertheless, if you want to use another data
 type entirely, that can be done).
 
 Since the Record can be accessed by any class that knows of EKRecord, it's also possible to add further data,
 in case the combination of Flags and Activity data isn't enough. It's not "officially" supported, but it can
 certainly be done.
 
 EKRecord is meant to be used as a singleton, and having multiple EKRecord objects in existence may lead to
 unknown/untested behaviors, especially since they all write data to the same NSUserDefaults dictionary.
 
 In the future, functionality for saving to iCloud or to actual files (as opposed to NSUserDefaults) may be
 added, but for now EKRecord works well enough.
 
 */

#import <UIKit/UIKit.h>

#pragma mark Definitions

#define EKRecordAutosaveSlotNumber      0   // ZERO is the autosave slot (slots 1 and above being "normal" save slots)

// These are keys for the "global" values in the record, 
#define EKRecordHighScoreKey            @"high score"       // Highest score achieved by anyone playing the game on this device
#define EKRecordDateSavedKey            @"date saved"       // The last time any data was saved on this device
#define EKRecordCurrentSlotKey          @"current slot"     // The most recently used slot
#define EKRecordUsedSlotNumbersKey      @"used slots array" // Lists all the arrays used so far

// Keys for data that's specific to a particular playthrough and is stored inside of individual "slots" (which contain a single
// NSData object that encapsulates all the other playthrough-specific data)
#define EKRecordDataKey                 @"record"               // THe NSData object that holds the dictionary with all the other saved-game data
#define EKRecordCurrentScoreKey         @"current score"        // NSUInteger of the player's current score
#define EKRecordFlagsKey                @"flag data"            // Key for a dictionary of "flag" data
#define EKRecordDateSavedAsString       @"date saved as string" // A string with a more human-readable version of the NSDate object

// Keys for activity data
#define EKRecordCurrentActivityDictKey  @"current activity" // Used to locate the activity data in the User Defaults
#define EKRecordActivityTypeKey         @"activity type" // Is this a VNScene, or some other kind of CCScene / activity type?
#define EKRecordActivityDataKey         @"activity data" // This will almost always be a dictionary with activity-specific data

#pragma mark - EKRecord

@interface EKRecord : NSObject
{
    // The record holds all data (scores, flags, activities, etc.) for a particular playthrough of the game.
    NSMutableDictionary* record;
}

// Which slot is being used for saved games
@property NSUInteger currentSlot;

#pragma mark - EKRecord functions

+ (EKRecord*)sharedRecord; // Singleton access

- (id)init;

#pragma mark Property functions

- (NSMutableDictionary*)record;

// NOTE: These next "properties" don't exist as part of the EKRecord class. Rather, they exist as key/value pairs
// in the "record" dictionary, and these functions are just ways of accessing that data in the dictionary.

- (NSMutableDictionary*)flags;
- (void)setFlags:(NSMutableDictionary*)updatedFlags;

- (void)setHighScore:(NSUInteger)highScoreValue;
- (NSUInteger)highScore;
- (void)setCurrentScore:(NSUInteger)scoreValue;
- (NSUInteger)currentScore;

- (void)setActivityDict:(NSDictionary*)activityDict;
- (NSDictionary*)activityDict;
- (void)resetActivityInformationInDict:(NSDictionary*)dict;

#pragma mark Slots Tracking

// The following are used to keep track of which slots have been used by EKRecord.
- (NSArray*)arrayOfUsedSlotNumbers; // Returns array of all the slot numbers that have been saved to thus far
- (void)addToUsedSlotNumbers:(NSUInteger)slotNumber; // Adds a particular slot number to the "used slots" array
- (BOOL)slotNumberHasBeenUsed:(NSUInteger)slotNumber; // Checks if a particular slot has been used

#pragma mark Flag functions

// Similar to the "property" functions above, these functions just modify the flag data that's stored
// in the record dictionary.

- (void)resetAllFlags;
- (void)addExistingFlags:(NSDictionary*)existingFlags; // Add existing flags from another dictionary to EKRecord's flag dictionary
- (id)flagNamed:(NSString*)nameOfFlag; // Retrieve a particular flag
- (int)valueOfFlagNamed:(NSString*)flagName;
- (void)setFlagValue:(id)flagValue forFlagNamed:(NSString*)nameOfFlag;
- (void)setIntegerValue:(int)iValue forFlag:(NSString*)nameOfFlag;
- (void)modifyIntegerValue:(int)iValue forFlag:(NSString*)nameOfFlag; // Use a positive number to "add" or a negative to subtract

#pragma mark Utility functions

- (NSString*)stringFromDate:(NSDate*)dateObject;    // Creates a human-readable string from raw NSDate data
- (void)updateDateInDictionary:(NSDictionary*)dict; // Updates the date in a dictionary (assumes dictionary is a saved game)

#pragma mark Loading functions

- (NSDictionary*)emptyRecord; // Creates a dictionary of new saved-game information, including "dummy" data
- (void)startNewRecord; // This "resets" EKRecord so that it will have brand-new data (as in a fresh saved game)
- (BOOL)hasAnySavedData; // Does this game have any saved-game data at all?

- (NSData*)dataFromSlot:(NSUInteger)slotNumber; // Loads NSData from a "slot" (a key/value pair in the NSUserDefaults dictionary)
- (NSDictionary*)recordFromData:(NSData*)data; // Creates an NSDictionary from NSData; assumes NSData holds saved game info
- (NSDictionary*)recordFromSlot:(NSUInteger)slotNumber; // "Shortcut" to load NSData from NSUserDefaults, then NSDictionary from that NSData
- (void)loadRecordFromCurrentSlot; // Takes whatever data might be in the current slot and overwrites EKRecord's "record" dictionary with it

#pragma mark Saving functions

- (NSData*)dataFromRecord:(NSDictionary*)dict; // Encodes saved game information in NSDictionary into NSData
- (void)saveData:(NSData*)data toSlot:(NSUInteger)slotNumber; // Saves NSData to a particular "slot" in NSUserDefaults
- (void)updateHighScore; // Checks if the current score is higher than the "high score" and updates the value stored in NSUserDefaults
- (void)saveCurrentRecord; // Saves the current record to a "slot" in NSUserDefaults (the exact slot number is based on 'currentSlot')

- (void)saveToDevice; // Saves the data stored in NSUserDefaults to device memory (this should happen on its own, but this speeds up the process)



@end
