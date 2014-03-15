//
//  EKRecord.m
//
//  Created by James Briones on 2/5/11.
//  Copyright 2011. All rights reserved.
//

#import "EKRecord.h"
//#import "VNLayer.h"

@implementation EKRecord

// A (supposedly) thread-safe singleton function
+ (EKRecord*)sharedRecord
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[EKRecord alloc] init];
    });
    return _sharedObject;
}

#pragma mark - Utility functions

// Convert a NSDate value into an easily-readable string value
- (NSString*)stringFromDate:(NSDate*)dateObject
{
    if( !dateObject ) // Check for invalid parameters
        return nil;
    
    // Set up the date formatter
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"h:mm a',' yyyy'-'MM'-'dd"]; // Example: "12:34 AM, 2013-02-10"
    NSString* formattedDate = [format stringFromDate:dateObject];
    
    return formattedDate;
}

// Set all time/date information in a save slot to the current time.
- (void)updateDateInDictionary:(NSDictionary*)dict
{
    if( !dict ) // Check for an invalid parameter
        return;
    
    // Get the current time, and then create a string displaying a human-readable version of the current time
    NSDate* theTimeRightNow = [NSDate date];
    NSString* stringWithCurrentTime = [self stringFromDate:theTimeRightNow];
    
    // Save all data into the dictionary, assuming the dictionary is mutable (it should be, but just to be sure...)
    if( [dict isKindOfClass:[NSMutableDictionary class]] ) {
        
        [dict setValue:theTimeRightNow forKey:EKRecordDateSavedKey];            // Save NSDate object
        [dict setValue:stringWithCurrentTime forKey:EKRecordDateSavedAsString]; // Save human-readable string
        
    } else {
        // Time for an error message...
        NSLog(@"[EKRecord] ERROR: Date information could not be saved; dictionary is immutable.");
    }
}

// Create new save data for a brand new game. The dictionary has no "real" data, but has several placeholders
// where actual data can be written into.
- (NSDictionary*)emptyRecord
{
    NSMutableDictionary* tempRecord = [NSMutableDictionary dictionary];
    
    // Fill the temporary record with default data
    [tempRecord setValue:@0 forKey:EKRecordCurrentScoreKey];    // This is a new game, so obviously there's no score yet
    [self updateDateInDictionary:tempRecord];                   // Set current date as "the time when this was saved"
    [self resetActivityInformationInDict:tempRecord];           // Fill the activity dictionary with dummy data
    
    // Create a flags dictionary with some default "dummy" data in it
    NSMutableDictionary* tempFlags = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"dummy value", @"dummy key", nil];
    [tempRecord setValue:tempFlags forKey:EKRecordFlagsKey]; // Load the flags dictionary into the record
    
    return [NSDictionary dictionaryWithDictionary:tempRecord];
}

// This "resets" EKRecord so that it will have brand-new data (as in a fresh saved game). HOWEVER it doesn't attept to save
// any previous data that might have existed... if you want to be sure that previous save data is actually saved, you'll have
// to call those functions yourself!
- (void)startNewRecord
{
    record = [[NSMutableDictionary alloc] initWithDictionary:[self emptyRecord]];
    [[NSUserDefaults standardUserDefaults] setValue:@(self.currentSlot) forKey:EKRecordCurrentSlotKey];
}

- (BOOL)hasAnySavedData
{
    BOOL result = YES; // At first, assume that there IS saved data. The rest of the function will check if this assumption is false!
    
    // This function will check if any of the following objects are missing, since a successful save should have put all of this into device memory
    NSDate* lastSavedDate = [[NSUserDefaults standardUserDefaults] objectForKey:EKRecordDateSavedKey];
    NSArray* usedSlotNumbers = [self arrayOfUsedSlotNumbers];
    
    if( !lastSavedDate || !usedSlotNumbers ) {
        result = NO;
    }
    
    return result;
}

#pragma mark - Properties

// There's a function to get the record, but not one to set it. That is, "record" is treated as a read-only variable.
- (NSMutableDictionary*)record
{
    return record;
}

// Returns the flags dictionary that's stored in the record... assuming that the record exists, that is!
// (If the record does exist, then the flags dictionary should also exist inside it too)
- (NSMutableDictionary*)flags
{
    if( !record )
        return nil;
    
    return [record objectForKey:EKRecordFlagsKey];
}

// Set the "flags" mutable dictionary in the record. If there's no record, it just gets created on the fly
- (void)setFlags:(NSMutableDictionary*)updatedFlags
{
    if( !record ) {
        NSLog(@"[EKRecord] Attempted to access flags, but no record existed. Autogenerating record...");
        record = [[NSMutableDictionary alloc] initWithDictionary:[self emptyRecord]];
    }
    
    // Flags will only get updated if the dictionary is valid
    if( updatedFlags ) {
        [record setValue:updatedFlags forKey:EKRecordFlagsKey];
    }
}

#pragma mark - Slots tracking

// This grabs an NSArray (filled with NSNumbers) from NSUserDefaults. The array keeps track of which "slots" have saved game information stored in them.
- (NSArray*)arrayOfUsedSlotNumbers
{
    // The array is considered a "global" value (that is, the same value is stored across multiple playthrough/saved-games)
    // so it would be found under the root dictionary of NSUserDefaults for this app.
    NSUserDefaults* deviceMemory = [NSUserDefaults standardUserDefaults];
    NSArray* tempArray = [deviceMemory objectForKey:EKRecordUsedSlotNumbersKey];
    
    if( tempArray == nil ) {
        NSLog(@"[EKRecord] Cannot find a previously existing array of used slot numbers.");
    }
    
    return tempArray;
}

// This just checks if a particular slot number has been used (reminder: the "autosave" slot is slot ZERO)
- (BOOL)slotNumberHasBeenUsed:(NSUInteger)slotNumber
{
    BOOL result = NO; // Assume NO by default; this gets changed if data proves otherwise
    
    // Check if there's any slot number data at all. If there isn't, then obviously none of the slot numbers have been used.
    NSArray* slotsUsed = [self arrayOfUsedSlotNumbers];
    if( !slotsUsed || slotsUsed.count < 1 ) {
        return result;
    }
    
    // The following loop checks every single index in the array and examines if the NSNumber stored within holds the value as the slot number we're checking for.
    for( NSUInteger i = 0; i < slotsUsed.count; i++ ) {
        
        NSNumber* currentNumber = [slotsUsed objectAtIndex:i];
        NSUInteger valueOfCurrentNumber = [currentNumber unsignedIntegerValue];
        
        // Check if the value that was found matches the value that was expected
        if( valueOfCurrentNumber == slotNumber ) {
            NSLog(@"[EKRecord] Match found for slot number %lu in index %lu", (unsigned long)slotNumber, (unsigned long)i); // Log success
            result = YES; // This slot number has indeed been used
        }
    }
    
    return result;
}

// This adds a particular value to the list of used slot numbers.
- (void)addToUsedSlotNumbers:(NSUInteger)slotNumber
{
    NSLog(@"[EKRecord] Will now attempt to add %lu to array of used slot numbers.", (unsigned long)slotNumber);
    BOOL numberWasAlreadyUsed = [self slotNumberHasBeenUsed:slotNumber];
 
    // If the number has already been used, then there's no point adding another mention of it; that would
    // up more memory to tell EKRecord something that it already knows. Information will only be added
    // if the slot number in question hasn't been used yet.
    if( numberWasAlreadyUsed == NO ) {
        
        NSLog(@"[EKRecord] Slot number %lu has not been used previously.", (unsigned long)slotNumber);
        NSMutableArray* slotNumbersArray = [[NSMutableArray alloc] init];
        
        // Check if there was any previous data. If there was, then it'll be added to the new array. If not... well, it's not a big deal!
        NSArray* previousSlotsArray = [self arrayOfUsedSlotNumbers];
        if( previousSlotsArray )
            [slotNumbersArray addObjectsFromArray:previousSlotsArray];
        
        // Add the slot number that was passed in to the newly-created array
        [slotNumbersArray addObject:@(slotNumber)];
        
        // Create a regular non-mutable NSArray and store the data there
        NSArray* unmutableArray = [[NSArray alloc] initWithArray:slotNumbersArray];
        NSUserDefaults* deviceMemory = [NSUserDefaults standardUserDefaults]; // Pointer to NSUserDefaults
        [deviceMemory setObject:unmutableArray forKey:EKRecordUsedSlotNumbersKey]; // Store the updated array in NSUserDefaults
        NSLog(@"[EKRecord] Slot number %lu saved to array of used slot numbers.", (unsigned long)slotNumber);
    }
}

#pragma mark - Score properties

// Sets the high score (stored in NSUserDefaults)
- (void)setHighScore:(NSUInteger)highScoreValue
{
    // Remember that the High Score is a global value and should be stored directly in NSUserDefaults instead of the slot/record section
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithUnsignedInteger:highScoreValue] forKey:EKRecordHighScoreKey];
}

- (NSUInteger)highScore
{
    NSUInteger result = 0; // The default value for the "high score" is zero
    
    // Try to get data from NSUserDefaults. Keep in mind that the High Score is a "global" value, and is shared across
    // multiple playthroughs (and so isn't something that can be kept in a particular slot/record), so it wouldn't be
    // stored in the slot/record like almost everything else.
    NSNumber* highScoreFromRecord = [[NSUserDefaults standardUserDefaults] objectForKey:EKRecordHighScoreKey];
    
    // It's entirely possible that no high score has been saved yet (either because this is a brand-new game
    // and nothing has been saved yet, or if the game just doesn't really bother with high score data), so it's
    // important to check if a valid value was returned.
    if( highScoreFromRecord ) {
        
        // Update 'result' with some actual data
        result = [highScoreFromRecord unsignedIntegerValue];
    }
    
    return result;
}

// Sets the current score. Unlike the High Score, the Current Score IS stored in the record/slot section.
- (void)setCurrentScore:(NSUInteger)scoreValue
{
    // If there's no current record, then just create one on the fly (and hope it works out!)
    if( !record ) {
        record = [[NSMutableDictionary alloc] initWithDictionary:[self emptyRecord]];
    }
    
    // Store the current score as an NSNumber in the record
    [record setValue:[NSNumber numberWithUnsignedInteger:scoreValue] forKey:EKRecordCurrentScoreKey];
}

// This will return the current score for this playthrough. If there isn't any record (or there's no scoring data
// in the record), then it will just return a zero.
- (NSUInteger)currentScore
{
    NSUInteger result = 0; // Assume zero by default
    
    if( record ) {
        
        NSNumber* scoreFromRecord = [record objectForKey:EKRecordCurrentScoreKey];
        
        if( scoreFromRecord )
            result = [scoreFromRecord unsignedIntegerValue];
    }
    
    return result;
}

#pragma mark - Loading data

// Load NSData from a "slot" stored in NSUserDefaults / device memory.
- (NSData*)dataFromSlot:(NSUInteger)slotNumber
{
    NSUserDefaults* deviceMemory = [NSUserDefaults standardUserDefaults];   // Pointer to where memory is stored in the device
    NSString* slotKey = [NSString stringWithFormat:@"slot%lu", (unsigned long)slotNumber];  // Generate name of the dictionary key where save data is stored
    
    NSLog(@"[EKRecord] Loading record from slot named [%@]", slotKey);
    
    // Try to load the data from the slot that should be stored in the device's memory.
    NSData* slotData = [deviceMemory objectForKey:slotKey];
    if( slotData == nil ) {
        NSLog(@"[EKRecord] ERROR: No data found in slot number %lu", (unsigned long)slotNumber );
        return nil;
    }
    
    // Note how large the data is
    NSLog(@"[EKRecord] 'dataFromSlot' has loaded an NSData object of size %lu bytes.", (unsigned long)slotData.length);
    
    return [NSData dataWithData:slotData];
}

// Load a dictionary with game record from an NSData object (which was loaded from memory)
- (NSDictionary*)recordFromData:(NSData*)data
{
    if( !data ) {
        NSLog(@"[EKRecord] ERROR: Could not load record; invalid data passed in!");
        return nil;
    }
    
    // Unarchive the information from NSData into NSDictionary
    NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSDictionary* dictFromData = [unarchiver decodeObjectForKey:EKRecordDataKey];
    [unarchiver finishDecoding];
    
    return [NSDictionary dictionaryWithDictionary:dictFromData];
}

// Load saved game data from a slot
- (NSDictionary*)recordFromSlot:(NSUInteger)slotNumber
{
    NSData* loadedData = [self dataFromSlot:slotNumber];
    return [self recordFromData:loadedData];
}

// This attempts to load a record from the "current slot," which is slotXX (where XX is whatever the heck 'self.currentSlot' is).
// If this sounds kind of vague and unhelpful... well, I suppose that says something about this function! :P
- (void)loadRecordFromCurrentSlot
{
    NSDictionary* tempDict = [self recordFromSlot:self.currentSlot];        // Load temporary dictionary from a particular slot in device memory
    
    if( tempDict ) { // Dictionary has valid data
    
        // Copy record data from device memory
        record = [[NSMutableDictionary alloc] initWithDictionary:tempDict];
        NSLog(@"[EKRecord] Record was successfully loaded from slot %lu", (unsigned long)self.currentSlot);
        
    } else { // No valid data in dictionary
        
        // Error
        NSLog(@"[EKRecord] ERROR: Could not load record from slot %lu.", (unsigned long)self.currentSlot);
    }
}

#pragma mark - Saving data

// Create an NSData object from a game record
- (NSData*)dataFromRecord:(NSDictionary*)dict
{
    // Check if the dictionary has no data (or if the dictionary simply doesn't exist)
    if( dict == nil || dict.count < 1 ) {
        NSLog(@"[EKRecord] ERROR: Cannot create data from record; invalid information passed in!");
        return nil;
    }
    
    // Update the date/time information in the record to "right now."
    [self updateDateInDictionary:dict];
    
    // Encode the dictionary into NSData format
    NSMutableData* data = [[NSMutableData alloc] init];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:dict forKey:EKRecordDataKey];
    [archiver finishEncoding];
    
    // Just note the size of the data object
    NSLog(@"[EKRecord] 'dataFromRecord' has produced an NSData object of size %lu bytes.", (unsigned long)data.length);
    
    return [NSData dataWithData:data];
}

// Saves NSData object to a particular "slot" (which is located in NSUserDefaults's root dictionary)
- (void)saveData:(NSData*)data toSlot:(NSUInteger)slotNumber
{
    if( !data ) {
        NSLog(@"[EKRecord] ERROR: Cannot save data to slot; data was invalid.");
        return;
    }
    
    // Store the NSData object into NSUserDefaults, under the key "slotXX" (XX being whatever value 'slotNumber' is)
    NSUserDefaults* deviceMemory = [NSUserDefaults standardUserDefaults];
    NSString* stringWithSlotNumber = [NSString stringWithFormat:@"slot%lu", (unsigned long)slotNumber]; // Dictionary key for slot
    [deviceMemory setValue:data forKey:stringWithSlotNumber]; // Store data in NSUserDefaults dictionary
    [self addToUsedSlotNumbers:slotNumber]; // Flag this slot number as being used
}

// This just checks if the current score is higher than the "high score" saved in NSUserDefaults. If that's the case, then
// the high score is set to the current score's value.
- (void)updateHighScore
{
    // This will only check for a current score if there's existing record data (which is where the current score is stored)
    if( record ) {
        
        // Try to get the scores. If, for some reason, there isn't any actual score data, then they'll just be set to zero
        NSUInteger theCurrentScore = [self currentScore];
        NSUInteger theHighScore = [self highScore];
        
        // Save the current score if it's higher than the High Score that's been saved
        if( theCurrentScore > theHighScore ) {
            [self setHighScore:theCurrentScore];
        }
    }
}

// If EKRecord is storing any data, then it will get stored to device memory (NSUserDefaults). The slot number being used
// would be whatever 'currentSlot' has as its value.
- (void)saveCurrentRecord
{
    if( !record ) {
        NSLog(@"[EKRecord] ERROR: No record data exists.");
        return;
    }
    
    // Update global data
    NSUserDefaults* deviceMemory = [NSUserDefaults standardUserDefaults];
    [deviceMemory setValue:[NSDate date] forKey:EKRecordDateSavedKey]; // Store current date as the "most recent save" date
    [deviceMemory setValue:[NSNumber numberWithUnsignedInteger:self.currentSlot] forKey:EKRecordCurrentSlotKey]; // Current slot
    
    // Update record information
    [self updateDateInDictionary:record];
    [self updateHighScore]; // Update high score also
    
    NSData* recordAsData = [self dataFromRecord:record];
    [self saveData:recordAsData toSlot:self.currentSlot];
    
    NSLog(@"[EKRecord] saveCurrentRecord - Record has been saved.");
}

#pragma mark - Initialization Code

/*- (void)dealloc
{
    NSLog(@"Record object deallocated; saving data to memory.");
    [self saveToDevice];
}*/

- (id)init
{
    if( (self = [super init]) ) {
        
        // Set default values
        self.highScore = 0;
        self.currentSlot = EKRecordAutosaveSlotNumber; // This would be ZERO
        
        // Get a handle to the device's 'user defaults' info
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        
        // Check what the most recently used save slot was.
        NSNumber* lastSavedSlot = [userDefaults objectForKey:EKRecordCurrentSlotKey];
        
        // If a slot number was found, then just get that value and overwrite the default slot number
        if( lastSavedSlot ) {
            self.currentSlot = [lastSavedSlot unsignedIntegerValue];
            NSLog(@"[EKRecord] Current slot set to %lu, which was the value stored in memory.", (unsigned long)self.currentSlot);
        }
        
        // If there's any previously-saved data, then just load that information. If there is NO previously-saved data, then just do nothing.
        // The reasoning here is that if there's previously-saved data, then it should be loaded by default (if the app or player wants to create
        // all new data, they can just do that manually). If no record exists, then it will be created either automatically once the app starts
        // trying to write flag data. Of course, it can also be created manually (like when a new game begins, EKRecord can be told to just
        // create a new record.
        if( [self hasAnySavedData] == YES ) {
            
            // Display all used slots (this is actually meant for diagnostic/testing purposes)
            NSArray* allUsedSlots = [self arrayOfUsedSlotNumbers];
            if( allUsedSlots ) {
                NSLog(@"[EKRecord] The following slots are in use: %@", allUsedSlots);
            }
            
            // Load the data from the current slot (which is the one with the most recent save data)
            [self loadRecordFromCurrentSlot];
            
            // Log success or failure
            if( record )
                NSLog(@"[EKRecord] Record initialized with data: %@", record);
            else
                NSLog(@"[EKRecord] Failed to initialize saved game data.");
        }
    }
    
    return self;
}

#pragma mark - Flags

// This removes any existing flag data and overwrites it with a blank dictionary that has dummy values
- (void)resetAllFlags
{
    // Create a brand-new dictionary with nothing but dummy data
    NSMutableDictionary* dummyFlags = [[NSMutableDictionary alloc] init];
    [dummyFlags setValue:@"dummy value" forKey:@"dummy key"];

    // Set this "dummy data" dictionary as the flags data
    [self setFlags:dummyFlags];
}

// Adds a dictionary of flags to the Flags data stored in EKRecord
- (void)addExistingFlags:(NSDictionary*)existingFlags
{
    if( !existingFlags || existingFlags.count < 1 ) // Check for invalid parameters
        return;
    
    // Check if no record data exists. If that's the case, then start a new record.
    if( !record )
        [self startNewRecord];
    
    [[self flags] addEntriesFromDictionary:existingFlags];
}

- (id)flagNamed:(NSString*)nameOfFlag
{
    if( !record )
        return nil;
    
    return [[self flags] objectForKey:nameOfFlag];
}

// Return the int value of a particular flag. It's important to keep in mind though, that while flags by default
// use int values, it's entirely possible that it might use something entirely different. It's even possible to use
// completely different types of objects (say, UIImage) as a flag value.
- (int)valueOfFlagNamed:(NSString*)flagName
{
    int result = 0;                           // Assume zero as the default value
    NSNumber* theFlag = [self flagNamed:flagName];  // Try to get a pointer to the flag
    
    // Check if any data was actually retrieved AND that this holds a number value (as opposed to, say, UIImage or
    // some entirely different type of class).
    if( theFlag && [theFlag isKindOfClass:[NSNumber class]]) {
        result = [theFlag intValue];
    }
    
    // If a flag was found, it will return that value. If no flag was found, then it will just return zero.
    return result;
}

// Sets the value of a flag
- (void)setFlagValue:(id)flagValue forFlagNamed:(NSString*)nameOfFlag
{
    if( !flagValue || !nameOfFlag ) // Check for invalid parameters
        return;
    
    // Automatically create a new record if one doesn't exist
    if( !record )
        [self startNewRecord];
    
    // Update flags dictionary with this value
    [[self flags] setValue:flagValue forKey:nameOfFlag];
}

// Sets a flag's int value. If you want to use a non-integer value (or something that's not even a number to begin with),
// then you shoule switch to 'setFlagValue' instead.
- (void)setIntegerValue:(int)iValue forFlag:(NSString*)nameOfFlag
{
    // Check if the flag name NSString is valid
    if( nameOfFlag ) {
        
        // Convert int to NSNumber and pass that into the flags dictionary
        NSNumber* tempValue = [NSNumber numberWithInteger:iValue];
        [self setFlagValue:tempValue forFlagNamed:nameOfFlag];
    }
}

// Adds or subtracts the integer value of a flag by a certain amount (the amount being whatever 'iValue' is).
- (void)modifyIntegerValue:(int)iValue forFlag:(NSString*)nameOfFlag
{
    if( !nameOfFlag ) // Function quits if no valid flag name is passed in
        return;
    
    // Create a record if there isn't one already
    if( !record )
        [self startNewRecord];
    
    // Get the original flag value
    NSNumber* numberObject = [[self flags] objectForKey:nameOfFlag];
    
    // If there is no value (or if it's not a number to begin with), then make it into an NSNumber with a value of zero
    if( numberObject == nil || ![numberObject isKindOfClass:[NSNumber class]])
        numberObject = [NSNumber numberWithInteger:0];
    
    int numberValue = [numberObject intValue];    // Convert from NSNumber to int
    numberValue = numberValue + iValue;                     // Modify value by 'iValue'
    
    // Save the updated value into the flags dictionary
    [self setFlagValue:@(numberValue) forFlagNamed:nameOfFlag];
}

#pragma mark - Activity data

// Sets the activity information in the record
- (void)setActivityDict:(NSDictionary*)activityDict
{
    // Check if there is both actual data AND a valid parameter being passed in... if neither exists, then the function won't work
    if( activityDict ) {
        
        if( !record )
            [self startNewRecord];
        
        // Set the activity dictionary
        [record setValue:activityDict forKey:EKRecordCurrentActivityDictKey];
    }
}

// Return activity data from record
- (NSDictionary*)activityDict
{
    NSDictionary* result = nil; // Assume there's no valid data by default
    
    // Check if the record exists, and if so, then try to grab the activity data from it. By default, there should be some sort of dictionary,
    // even if it's just nothing but dummy values.
    if( record ) {
        result = [record objectForKey:EKRecordCurrentActivityDictKey];
    }
    
    return result;
}

// This just resets all the activity information stored by a particular dictionary back to its default values (that is, "dummy" values).
// The "dict" being passed in should be a record dictionary of some kind (ideally, the 'record' dictionary stored by EKRecord)
- (void)resetActivityInformationInDict:(NSDictionary*)dict
{
    // Check if the pointer to the dictionary is valid
    if( dict ) {
        
        // Fill out the activity information with useless "dummy data." Later, this data can (and should) be overwritten there's actual data to use
        NSMutableDictionary* informationAboutCurrentActivity = [[NSMutableDictionary alloc] initWithObjectsAndKeys: @"nil", @"scene to play", nil]; // Empty visual-novel scene
        NSMutableDictionary* activityDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys: @"nil", EKRecordActivityTypeKey,
                                             informationAboutCurrentActivity, EKRecordActivityDataKey,
                                             nil];
        [dict setValue:activityDict forKey:EKRecordCurrentActivityDictKey]; // Store the dummy data into the record
    }
}

// For saving/loading to device. This should cause the information stored by EKRecord to being put to NSUserDefaults, and then
// it would "synchronize," so that the data would be stored directly into the device memory (as opposed to just sitting in RAM).
- (void)saveToDevice
{
    NSLog(@"[EKRecord] Will now attempt to save information to device memory.");
    
    if( record ) {
        NSLog(@"[EKRecord] Saving record to device memory...");
        [self saveCurrentRecord];
        
        // Now "synchronize" the data so that everything in NSUserDefaults will be moved from RAM into the actual device memory.
        // NSUserDefaults synchronizes its data every so often, but in this case it will be done manually to ensure that EKRecord's data
        // will be moved into device memory.
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else if ( !record ) {
        NSLog(@"[EKRecord] ERROR: Cannot save information because no record exists.");
    }
}

@end
