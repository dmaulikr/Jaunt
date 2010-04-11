//
//  WeatherController.h
//  Jaunt
//
//  Created by John Bowles on 10/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Trip;
@class ActivityManager;

@interface WeatherController : UITableViewController <UITableViewDelegate, UITableViewDataSource> {

	Trip *trip;
	NSMutableArray *forecasts;

@private
	ActivityManager *activityManager;
}

@property (nonatomic, retain) Trip *trip;
@property (nonatomic, retain) NSMutableArray *forecasts;
@property (nonatomic, retain) ActivityManager *activityManager;

@end
