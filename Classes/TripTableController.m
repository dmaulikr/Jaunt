//
//  TripTableController.m
//  Jaunt
//
//  Created by John Bowles on 10/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TripTableController.h"
#import "JauntAppDelegate.h"
#import	"AddTripController.h"
#import	"EditTripController.h"
#import "CoreData/CoreData.h"
#import "Trip.h"
#import	"Logger.h"
#import "CoreDataManager.h"

@implementation TripTableController

@synthesize tripsCollection;
@synthesize navigationController;

#pragma mark -
#pragma mark View Management

- (void)viewDidLoad {
	
	[super viewDidLoad];
		
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTrip)];
	addButton.enabled = YES;
	
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = addButton;
	
	[addButton release];
}

- (void) viewWillAppear:(BOOL) animated {
	
	[super viewWillAppear:animated];
	[self loadTrips];
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Persistence

- (NSManagedObjectContext *) getManagedObjectContext {
    
	JauntAppDelegate *aDelegate = [[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *aContext = [aDelegate managedObjectContext];
	
    return aContext;
}

- (void) loadTrips {

	NSMutableArray *results = [CoreDataManager executeFetch:[self getManagedObjectContext] forEntity:@"Trip" withPredicate:nil usingFilter:@"name"];
	[self setTripsCollection: results];
}

#pragma mark -
#pragma mark Methods

- (void) addTrip {

	AddTripController *addTripController = [[AddTripController alloc] initWithStyle: UITableViewStyleGrouped];
	addTripController.title = @"Add Trip";
	
	JauntAppDelegate *aDelegate = [[UIApplication sharedApplication] delegate];
	[aDelegate.navigationController pushViewController:addTripController animated:YES];
	[addTripController release];
}

#pragma mark -
#pragma mark Table Data Source Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	return [self.tripsCollection count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *reuseIdentifer = @"TripNameCellIdentifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: reuseIdentifer];
	
	if (cell == nil) {
		
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:reuseIdentifer] autorelease];
	}
	
	Trip *aTrip = [self.tripsCollection objectAtIndex: [indexPath row]];
	
	cell.textLabel.text = [aTrip name];	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
}

/**
 Handle deletion of an event.
 */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		NSManagedObjectContext *aContext = [self getManagedObjectContext];
		
        // Delete the managed object at the given index path.
		NSManagedObject *trip = [self.tripsCollection objectAtIndex:indexPath.row];
		[aContext deleteObject:trip];
		
		// Update the array and table view.
        [self.tripsCollection removeObjectAtIndex: indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject: indexPath] withRowAnimation:YES];
		
		// Commit the change.
		NSError *error;
		if (![aContext save:&error]) {
			
			[Logger logError:error withMessage:@"Failed to delete trip"];
		}
    }   
}

#pragma mark -
#pragma mark Table Delegate Methods

- (void)tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath 
{
	Trip *aTrip = [self.tripsCollection objectAtIndex:indexPath.row];
	
	EditTripController	*editTripController = [[EditTripController alloc] initWithStyle: UITableViewStyleGrouped];
	editTripController.title = @"Edit Trip";
	editTripController.trip = aTrip;
	
	JauntAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate.navigationController pushViewController:editTripController animated:YES];
	
	[editTripController release];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {

	[tripsCollection release];
	[navigationController release];
    [super dealloc];
}

@end
