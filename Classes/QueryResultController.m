//
//  QueryResultController.m
//  Jaunt
//
//  Created by John Bowles on 3/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "QueryResultController.h"
#import "ActivityManager.h"
#import "GDataUtilities.h"
#import "GoogleServices.h"
#import "GoogleQuery.h"
#import "GoogleEntry.h"
#import "GDataGoogleBase.h"
#import "QueryDetailController.h"
#import "QueryDetailWebViewController.h"
#import "JauntAppDelegate.h"
#import "Logger.h"
#import "ReachabilityManager.h"


@interface QueryResultController (PrivateMethods)

-(void) performRefresh;

@end

@implementation QueryResultController

@synthesize googleEntry;
@synthesize currentLocation;
@synthesize googleQuery;
@synthesize results;
@synthesize activityManager;
@synthesize reachability;


#pragma mark -
#pragma mark View Management

-(void)viewDidLoad {
	
    [super viewDidLoad];
	
	ActivityManager *anActivityManager = [[ActivityManager alloc] initWithView:self.tableView];
	self.activityManager = anActivityManager;
	[anActivityManager release];
	[self.activityManager showActivity];
	
	ReachabilityManager *aReachability = [[ReachabilityManager alloc] initWithInternet];
	aReachability.delegate = self;
	self.reachability = aReachability;
	[aReachability release];
	
	[self performRefresh];
}

-(void) viewWillAppear:(BOOL)animated {
	
	[self.reachability startListener];
}

-(void) viewWillDisappear:(BOOL)animated {
	
	[self.reachability stopListener];
}

#pragma mark -
#pragma mark ReachabilityDelegate Callback

-(void) notReachable {
	
	[self.activityManager hideActivity];
	
	NSString *aMessage = @"Unable to connect to the network to display the Google search results.";
	UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:@"Network Unavailable" message:aMessage
													 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[anAlert show];	
	[anAlert release];
}

-(void) reachable {
	
	[self.activityManager showActivity];
	
	NSString *baseQuery = [self.googleEntry getQuery];
	NSString *orderBy = [self.googleEntry getOrderBy];
	
	[GoogleServices executeQueryUsingDelegate:self selector:@selector(ticket:finishedWithFeed:error:) baseQuery:baseQuery orderBy:orderBy];
}

-(void) performRefresh {
	
	if ([self.reachability isCurrentlyReachable] == YES) {
		
		[self reachable];
		
	} else {
		
		[self notReachable];
	}
}

#pragma mark -
#pragma mark Google Base Query Callbacks

-(void)ticket:(GDataServiceTicket *) aTicket finishedWithFeed:(GDataFeedBase *) aFeed error:(NSError *) anError {
	
	NSMutableArray *queryResults = [NSMutableArray array];
	
	for (GDataEntryGoogleBase *entry in [aFeed entries]) {
	
		GoogleQuery *aResult = [[GoogleQuery alloc] init];
		
		aResult.title = [self.googleEntry formatTitleWithEntry:entry];
		aResult.subTitle = [self.googleEntry formatSubTitleWithEntry:entry andAddress: [entry location]];
		aResult.detailedDescription = [self.googleEntry formatDetailsWithEntry:entry];
		aResult.address = [entry location];
		aResult.href = [[entry alternateLink] href];
		aResult.mapsURL = [GoogleServices mapsURLWithAddress:[entry location] andLocation:[self currentLocation]];
		
		[queryResults addObject:aResult];
		[aResult release];
	}
	
	[self.activityManager hideActivity];
	[self setResults: queryResults];
	[self.tableView reloadData];
	
	if ([[aFeed entries] count] == 0) {
	
		UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:[self.googleEntry getTitle] message:@"No results found"
													 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[anAlert show];	
		[anAlert release];
	}
}

#pragma mark -
#pragma mark Table Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	return [self.results count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *reuseIdentifer = @"ActionCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: reuseIdentifer];
	
	if (cell == nil) {
		
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifer] autorelease];
	}
	
	GoogleQuery *aQuery = [self.results objectAtIndex: [indexPath row]];
	cell.textLabel.text = [aQuery.title capitalizedString];	
	cell.detailTextLabel.text = [aQuery.subTitle capitalizedString];
	cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	
	return cell;
}

#pragma mark -
#pragma mark Table Delegate Methods

- (void)tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath 
{
	[self.tableView deselectRowAtIndexPath:indexPath animated: NO];
	
	self.googleQuery = [self.results objectAtIndex:indexPath.row];
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
													otherButtonTitles:@"Directions", @"Website", nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	actionSheet.cancelButtonIndex = 2;
	[actionSheet showInView: self.view];
	[actionSheet release];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
	[self.tableView deselectRowAtIndexPath:indexPath animated: NO];
	
	GoogleQuery *aQuery = [self.results objectAtIndex:indexPath.row];
	
	JauntAppDelegate *aDelegate = [[UIApplication sharedApplication] delegate];
	QueryDetailController *aController = [[QueryDetailController alloc] init];
	[aController setTitle:aQuery.title];
	[aController setGoogleQuery:aQuery];
	[aDelegate.navigationController pushViewController:aController animated:YES];
	[aController release];
}

#pragma mark -
#pragma mark ActionSheet Navigation 

- (void) actionSheet:(UIActionSheet *) actionSheet clickedButtonAtIndex:(NSInteger) buttonIndex
{
	if (buttonIndex == 0)
	{
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.googleQuery.mapsURL]];
	}
	if (buttonIndex == 1)
	{
		JauntAppDelegate *aDelegate = [[UIApplication sharedApplication] delegate];
		QueryDetailWebViewController *aController = [[QueryDetailWebViewController alloc] init];
		[aController setTitle:self.googleQuery.title];
		[aController setQueryDetailUrl:self.googleQuery.href];
		[aDelegate.navigationController pushViewController:aController animated:YES];
		[aController release];
	}
}

#pragma mark -
#pragma mark Memory Management

-(void)dealloc {
    
	[googleEntry release];
	[currentLocation release];
	[googleQuery release];
	[results release];
	[activityManager release];
	[reachability release];
	[super dealloc];
}

@end
