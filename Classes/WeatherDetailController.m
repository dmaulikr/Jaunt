//
//  WeatherDetailController.m
//  Jaunt
//
//  Created by John Bowles on 4/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "WeatherDetailController.h"
#import "Forecast.h"
#import "ForecastDetail.h"

@implementation WeatherDetailController

@synthesize forecast;


#pragma mark -
#pragma mark View Management

- (void)viewDidLoad {
	
	[super viewDidLoad];
}

#pragma mark -
#pragma mark Table Data Source Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	return [self.forecast.forecastDetails count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *reuseIdentifer = @"ForecastDetailCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: reuseIdentifer];
	
	if (cell == nil) {
		
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifer] autorelease];
	}
	
	ForecastDetail *aForecastDetail = [self.forecast.forecastDetails objectAtIndex: [indexPath row]];
	
	NSDateFormatter *aDateFormatter = [[NSDateFormatter alloc] init];
	[aDateFormatter setDateFormat:@"EEEE, MMMM d"];
	NSString *aDate = [aDateFormatter stringFromDate:aForecastDetail.date];
	[aDateFormatter release];
	
	NSString *hiLow = [NSString stringWithFormat:@"High/Low: %@ / %@\u2070 F", aForecastDetail.maxTemp, aForecastDetail.minTemp];
	cell.textLabel.text = [NSString stringWithFormat:@"%@", aDate];	
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  Precipitation: %@%%", hiLow, aForecastDetail.probabilityOfPrecipitation];
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	return cell;
}


#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    
	[forecast release];
	[super dealloc];
}


@end
