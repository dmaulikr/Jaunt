//
//  QueryResultController.h
//  Jaunt
//
//  Created by John Bowles on 3/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class GoogleEntry;
@class GoogleQuery;
@class ActivityManager;

@interface QueryResultController : UITableViewController <UITableViewDelegate, UIActionSheetDelegate> {

	GoogleEntry *googleEntry;
	CLLocation *currentLocation;

@private
	GoogleQuery *googleQuery;
	NSMutableArray *results;
	ActivityManager *activityManager;
}

@property (nonatomic, retain) GoogleEntry *googleEntry;
@property (nonatomic, retain) CLLocation *currentLocation;
@property (nonatomic, retain) GoogleQuery *googleQuery;
@property (nonatomic, retain) NSArray *results;
@property (nonatomic, retain) ActivityManager *activityManager;

@end