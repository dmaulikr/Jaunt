//
//  DateUtils.h
//  Jaunt
//
//  Created by John Bowles on 4/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DateUtils : NSObject {

}

+(NSString *) dayOfWeek:(NSDate *) aDate;
+(NSString *) morningOrEvening:(NSUInteger) hour;	
+(NSDate *) addDays:(NSUInteger) days toDate:(NSDate *) aDate;
+(NSDate *) addDaysToCurrentDate:(NSUInteger) days;

@end
