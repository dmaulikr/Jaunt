//
//  DestinationController.m
//  Jaunt
//
//  Created by John Bowles on 11/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import	"JauntAppDelegate.h"
#import "DestinationController.h"
#import "TextFieldCell.h"
#import "CellManager.h"
#import "CellExtension.h"
#import "Trip.h"
#import "Destination.h"
#import "City.h"
#import "TextFieldExtension.h"
#import "IndexedTextField.h"
#import	"Logger.h"
#import "CoreDataManager.h"
#import "ActivityManager.h"
#import "ReachabilityManager.h"


@implementation DestinationController

@synthesize toolBar;
@synthesize titles;
@synthesize values;
@synthesize trip;
@synthesize destination;
@synthesize cellManager;
@synthesize searchDisplayController;
@synthesize cities;
@synthesize fetchedResultsController;
@synthesize locationManager;
@synthesize activityManager;
@synthesize queue;
@synthesize reverseGeoCoder;
@synthesize reachability;


#pragma mark -
#pragma mark View Management


- (void) viewDidLoad {
	
	[super viewDidLoad];	
	
	UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
	self.navigationItem.rightBarButtonItem = saveButton;
	[saveButton release];
	
	ActivityManager *anActivityManager = [[ActivityManager alloc] initWithView:self.view];
	self.activityManager = anActivityManager;
	[anActivityManager release];
	
	CLLocationManager *aLocationManager = [[CLLocationManager alloc] init];
	aLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
	aLocationManager.distanceFilter = kCLDistanceFilterNone;
	aLocationManager.delegate = self;
	self.locationManager = aLocationManager;
	[aLocationManager release];
	
	NSOperationQueue *aQueue = [[NSOperationQueue alloc] init];
	[aQueue setMaxConcurrentOperationCount:1];
	self.queue = aQueue;
	[aQueue release];
	
	ReachabilityManager *aReachability = [[ReachabilityManager alloc] initWithHost:@"www.apple.com"];
	aReachability.delegate = self;
	self.reachability = aReachability;
	[aReachability release];
	
	[self loadTitles];
	[self loadCells];
	[self loadValues];
	[self configureSearchDisplay];
	[self configureToolBar];
}

-(void) viewWillAppear:(BOOL)animated {
	
	[self.reachability startListener];
}

-(void) viewWillDisappear:(BOOL)animated {
	
	[self.reachability stopListener];
	[self.toolBar removeFromSuperview];
}

#pragma mark -
#pragma mark Post-Initialization Methods

- (void) loadTitles {
	
	NSArray *array = [[NSArray alloc] initWithObjects:@"Name:", @"City:", @"State:", nil];
	[self setTitles: array];
	[array release];
}

- (void) loadCells {
	
	NSArray *nibNames = [NSArray arrayWithObjects:@"TextFieldCell", nil];
	NSArray *identifiers = [NSArray arrayWithObjects:@"TextFieldCell", nil];
	
	CellManager *manager = [[CellManager alloc] initWithNibs:nibNames withIdentifiers:identifiers forOwner:self];
	self.cellManager = manager;
	[manager release];
}

- (void) loadValues {

	if (self.values == nil) {
		
		NSMutableArray *destinationValues = [[NSMutableArray alloc] initWithObjects: @"", @"", @"", nil];
		self.values = destinationValues;
		[destinationValues release];
	}
	[self.values replaceObjectAtIndex:0 withObject: self.destination.name];
	[self.values replaceObjectAtIndex:1 withObject: self.destination.city];
	[self.values replaceObjectAtIndex:2 withObject: self.destination.state];
}

-(void) configureSearchDisplay {

	NSMutableArray *anArray = [[NSMutableArray alloc] init];
	self.cities = anArray;
	[anArray release];
	
	UISearchBar *aSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 0)];
	aSearchBar.delegate = self;  
    aSearchBar.showsCancelButton = YES;  
	aSearchBar.placeholder = @"Search for city and state";
	aSearchBar.keyboardType = UIKeyboardTypeASCIICapable;
	aSearchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	aSearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [aSearchBar sizeToFit];  
    self.tableView.tableHeaderView = aSearchBar;  
	
	UISearchDisplayController *aSearchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:aSearchBar contentsController:self];  
	aSearchDisplayController.searchResultsDataSource = self;
	aSearchDisplayController.searchResultsDelegate = self;
	[aSearchDisplayController setDelegate:self];  
	[self setSearchDisplayController:aSearchDisplayController];
	
	[aSearchBar release];
	[aSearchDisplayController release];
}

-(void) configureToolBar {
	
	UIBarButtonItem *aBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
																					target:self action:@selector(showActions:)];
	aBarButtonItem.style = UIBarButtonItemStyleBordered;
	
	UIToolbar *aToolbar = [[UIToolbar alloc] init];
	aToolbar.barStyle = UIBarStyleDefault;
	[aToolbar sizeToFit];
	
	CGFloat toolbarHeight = [aToolbar frame].size.height;
	CGRect aRectangle = self.tableView.bounds;
	[aToolbar setFrame:CGRectMake(CGRectGetMinX(aRectangle),
								  CGRectGetMinY(aRectangle) + CGRectGetHeight(aRectangle) - (toolbarHeight * .60),
								  CGRectGetWidth(aRectangle),
								  48.0)];

	NSArray *items = [NSArray arrayWithObjects: aBarButtonItem, nil];
	[aToolbar setItems:items animated:NO];
	
	[self.navigationController.view addSubview:aToolbar];
	self.toolBar = aToolbar;
	
	[aToolbar release];
	[aBarButtonItem release];
}

-(void) showActions:(id) sender {
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
													otherButtonTitles:@"Add Current Location", nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	actionSheet.cancelButtonIndex = 4;
	[actionSheet showInView: self.view];
	[actionSheet release];
}

#pragma mark -
#pragma mark ActionSheet Navigation 

- (void) actionSheet:(UIActionSheet *) actionSheet clickedButtonAtIndex:(NSInteger) buttonIndex
{	
	if (buttonIndex == 0 && self.locationManager.locationServicesEnabled)
	{
		[self.activityManager showActivity];
		[self.locationManager startUpdatingLocation];
	}
}

#pragma mark -
#pragma mark ReachabilityDelegate Callback

-(void) notReachable {
	
	UIBarButtonItem *aBarButtonItem = [self.toolBar.items objectAtIndex:0];
	aBarButtonItem.enabled = NO;
	
	NSString *aMessage = @"Unable to connect to the network. However, you can still add a destination manually via the search feature.";
	UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:@"Network Unavailable" message:aMessage
													 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[anAlert show];	
	[anAlert release];
}

-(void) reachable {
	
	UIBarButtonItem *aBarButtonItem = [self.toolBar.items objectAtIndex:0];
	aBarButtonItem.enabled = YES;
}


#pragma mark -
#pragma mark Persistence

- (void) save {
	
	JauntAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *aContext = [delegate getManagedObjectContext];
	
	self.destination.name = [self.values objectAtIndex:0];
	self.destination.city = [self.values objectAtIndex:1];
	self.destination.state = [self.values objectAtIndex:2];
	
	NSError *error;
	
	if (![aContext save: &error]) {
		
		[Logger logError:error withMessage:@"Failed to save destination"];
	}
	UINavigationController *aController = [delegate navigationController];
	[aController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Table Data Source Methods

- (NSInteger)tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
	
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        return [self.cities count];
		
    } else {
		
		return self.titles.count;
	}
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
	
	return 1;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
	if (self.tableView == tableView) {
		
		static NSString *reuseIdentifer = @"TextFieldCell";
		UITableViewCell *cell = (UITableViewCell *) [tableView dequeueReusableCellWithIdentifier: reuseIdentifer];
		
		if (cell == nil) {
			
			cell = [self.cellManager cellForSection:indexPath.section];
			UITextField *aField = [cell indexedTextField];
			[aField setIndexPathForField: indexPath];
		}
		
		[cell setCellExtensionDelegate:self];
		[cell setValueForCell: [self.values objectAtIndex:indexPath.row]];
		[cell setTitleForCell: [self.titles objectAtIndex:indexPath.row]];
		
		return cell;
		
	} else {
		
		static NSString *searchIdentifer = @"SearchCell";
		UITableViewCell *cell = (UITableViewCell *) [tableView dequeueReusableCellWithIdentifier: searchIdentifer];
		
		if (cell == nil) {
			
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:searchIdentifer] autorelease];
		}
		
		City *aCity = [self.cities objectAtIndex:indexPath.row];
		cell.textLabel.text = [NSString stringWithFormat:@"%@, %@", [aCity.cityName capitalizedString], aCity.stateCode];
		
		return cell;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		
        City *aCity = [self.cities objectAtIndex:indexPath.row];
		NSArray *anArray = [NSArray arrayWithObjects:[aCity.cityName capitalizedString], [aCity.cityName capitalizedString], aCity.stateCode, nil];		
		[self.values setArray:anArray];
		
		[self.destination setLatitude:aCity.latitude];
		[self.destination setLongitude:aCity.longitude];
		
		[self.searchDisplayController setActive:NO];
		[self.tableView reloadData];
	}
}

#pragma mark -
#pragma mark UITextFieldDelegate Methods

- (void) textFieldDidBeginEditing:(UITextField *) aTextField {
	
	self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void) textFieldDidEndEditing:(UITextField *) aTextField {
	
	NSIndexPath *anIndexPath = [aTextField indexPathForField];
	[self.values replaceObjectAtIndex:anIndexPath.row withObject: aTextField.text];
	self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *) aTextField {
	
	NSIndexPath *anIndexPath = [aTextField indexPathForField];
	
	// Destination name can be edited, not the city and state.
	if (anIndexPath.row == 0) {
		return YES;
	}
	return NO;
}

#pragma mark -
#pragma mark UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	
	[searchBar resignFirstResponder];
}

#pragma mark -
#pragma mark UISearchDisplayControllerDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
	
	NSArray *operations = [self.queue operations];
	
	if ([operations count] == 0) {

		NSArray *arguments = [NSArray arrayWithObjects:searchString, [self fetchedResultsController], nil];
		NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(asyncSearch:) object:arguments];
		[self.queue addOperation:operation];
		[operation release];
	}
	
	return NO;
}

-(void) asyncSearch:(id) anArray {
	
	NSAutoreleasePool *aPool = [[NSAutoreleasePool alloc] init];
	
	NSArray *arguments = (NSArray *) anArray;
	NSString *aSearchString = (NSString *) [arguments objectAtIndex:0];
	
	NSFetchedResultsController *aController = (NSFetchedResultsController *) [arguments objectAtIndex:1];
	NSPredicate *aPredicate = [NSPredicate predicateWithFormat:@"%K beginswith[cd]%@",@"cityName", aSearchString];
	[aController.fetchRequest setPredicate:aPredicate];
	
	NSError *error;
	NSArray *results = nil;
	
	if([aController performFetch:&error]) {
		
		results = [aController fetchedObjects];
	}
	
	[self performSelectorOnMainThread:@selector(finishedSearching:) withObject:results waitUntilDone:YES];
	[aPool drain];
}

-(void) finishedSearching:(NSArray *) results {
	
	[self.cities removeAllObjects];
	
	if (results != nil && [results count] > 0) {
	
		[self.cities setArray: results];
	}
	[self.searchDisplayController.searchResultsTableView reloadData];
}

#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController != nil) {
        
		return fetchedResultsController;
    }
    
	JauntAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *aContext = [delegate getManagedObjectContext];
	self.fetchedResultsController = [CoreDataManager fetchedResultsController:aContext forEntity:@"City" columnName:@"cityName" delegate:self];
	
	return fetchedResultsController;
}

#pragma mark -
#pragma mark Core Location

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	
	[self.locationManager stopUpdatingLocation];
	
	CLLocationCoordinate2D coordinate = [newLocation coordinate];
	[self.destination setLatitude:[NSNumber numberWithDouble:coordinate.latitude]];
	[self.destination setLongitude:[NSNumber numberWithDouble:coordinate.longitude]];
	
	MKReverseGeocoder *aGeocoder = [[MKReverseGeocoder alloc] initWithCoordinate:coordinate];
	aGeocoder.delegate = self;
	self.reverseGeoCoder = aGeocoder;
	[aGeocoder release];
	[self.reverseGeoCoder start];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	
	if (error.code == kCLErrorDenied) {
		
		[self.locationManager stopUpdatingLocation];
	}
}

#pragma mark -
#pragma mark MKReverseGeocoder

- (void)reverseGeocoder:(MKReverseGeocoder *) aGeocoder didFindPlacemark:(MKPlacemark *)placemark {
	
	[self.activityManager hideActivity];
	
	if (placemark != nil && placemark.locality != nil && placemark.administrativeArea != nil) {
		
		NSArray *anArray = [NSArray arrayWithObjects:placemark.locality, placemark.locality, placemark.administrativeArea, nil];		
		[self.values setArray:anArray];
		[self.tableView reloadData];
		
	} else {
		
		UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:@"Location Status" message:@"Unable to determine city and state."
														 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[anAlert show];	
		[anAlert release];
	}
}

- (void)reverseGeocoder:(MKReverseGeocoder *)aGeocoder didFailWithError:(NSError *)error {

	[self.activityManager hideActivity];
	
	UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:@"Location Status" message:@"Unable to determine city and state."
												delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[anAlert show];	
	[anAlert release];
}

#pragma mark -
#pragma mark Memory Management

- (void) dealloc {
	
	[toolBar release];
	[titles release];
	[values release];
	[trip release];
	[destination release];
	[cellManager release];
	[searchDisplayController release];
	[cities release];
	[fetchedResultsController release];
	[locationManager release];
	[activityManager release];
	[queue release];
	[reverseGeoCoder release];
	[reachability release];
	[super dealloc];
}

@end
