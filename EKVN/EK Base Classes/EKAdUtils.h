//
//  EKAdUtils.h
//  EKVN
//
//  Created by James on 2/3/16.
//  Copyright © 2016 James Briones. All rights reserved.
//

#ifndef EKAdUtils_h
#define EKAdUtils_h

// Ads notifications
#define EKUtilsShowAdsNotificationID        @"EKUtilsShowAdsNotificationID"
#define EKUtilsHideAdsNotificationID        @"EKUtilsHideAdsNotificationID"

// Ads
BOOL EKAdsShouldNeverShowAds(); // retrieves value from NSUserDefaults about whether or not ads can ever be shown
void EKAdsSetShouldNeverShowAds(BOOL value); // updates NSUserDefaults value about whether or not ads can ever be shown
void EKAdsSetShowAds(BOOL value);
BOOL EKAdsCanShowAds();
void EKAdsHandleDisplayOfAds(); // handles displaying of ads (can be used to update ad display based on show/don't-show state machine
CGFloat EKAdsHeightOfBanner();


#endif /* EKAdUtils_h */
