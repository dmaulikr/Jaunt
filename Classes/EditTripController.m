//
//  EditTripController.m
//  Jaunt
//
//  Created by John Bowles on 11/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EditTripController.h"
#import "Trip.h"
#import "JauntAppDelegate.h"
#import "TextFieldCell.h"
#import	"CellManager.h"
#import	"CellExtension.h"

@implementation EditTripController

@synthesize list;
@synthesize tripsCollection;
@synthesize trip;
@synthesize managedObjectContext;
@synthesize tripName;
@synthesize cellManager;

#pragma mark -
#pragma mark View Management Methods

- (void)viewDidLoad {
	
	[super viewDidLoad];
	
	NSArray *array = [[NSArray alloc] initWithObjects:@"Name:", @"Add Destination", nil];
	[self setList: array];
	[array release];
	
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.navigationItem.rightBarButtonItem.target = self;
	self.navigationItem.rightBarButtonItem.action = @selector(toggleEditMode);
	
	[self loadCells];
}

- (void) toggleEditMode {
	
	if (self.tableView.editing == NO) {
		
		[self setEditing:YES animated:YES];
		
	} else {

		[self save];
	}
}

- (void)viewDidUnload {
	
	
}

#pragma mark -
#pragma mark Cell Management Methods

- (void) loadCells {

	NSArray *nibNames = [NSArray arrayWithObjects:@"TextFieldCell", @"NonEditableCell", nil];
	CellManager *manager = [[CellManager alloc] initWithNibs:nibNames forOwner:self];
	self.cellManager = manager;
	
	[manager release];
}

#pragma mark -
#pragma mark Persistence Methods

- (void) save {
	
	[self.trip setName:self.tripName];
	
	NSError *error;
	
	if (![managedObjectContext save: &error]) {
		// Handle the error.
	}
	// Have parent view reload its data
	JauntAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	
	UINavigationController *navController = [delegate navigationController];
	[navController popViewControllerAnimated:YES];
	
	NSArray *allControllers = navController.viewControllers;
	UITableViewController *parent = [allControllers lastObject];
	[parent.tableView reloadData];
}

#pragma mark -
#pragma mark Table Data Source Methods

- (NSInteger)tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
	
	if (section == 0) {
		
		return 1;
	} else {
		
		NSSet *destinations = [[self trip] destinations];
		return destinations.count + 1;
	}
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {

	return 2;
}

- (NSString *) tableView:(UITableView *) tableView titleForHeaderInSection:(NSInteger) section {
	
	NSString *titleName = @"Trip";
	
	if (section == 1) {
		
		titleName = @"Destinations";
	} 
	return titleName;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath: (NSIndexPath *)indexPath
{
	if (indexPath.section == 1) {
		
		return UITableViewCellEditingStyleInsert;
	}
	return UITableViewCellEditingStyleNone;

}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleInsert) {
		
		
    }  
	[self save];
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
	
	UITableViewCell *customCell = [self.cellManager cellForSection:indexPath.section];
	UITableViewCell *cell = (UITableViewCell *) [tableView dequeueReusableCellWithIdentifier: customCell.reuseIdentifier];
	
	if (cell == nil) {
		cell = customCell;
	}
	
	[cell setCellExtensionDelegate:self];
	[cell setValueForCell: self.trip.name];
	[cell setTitleForCell: [self.list objectAtIndex:indexPath.section]];
	
	return cell;
}

#pragma mark -
#pragma mark Table Delegate Methods

- (void)tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark UITextFieldDelegate Methods

- (void) textFieldDidEndEditing:(UITextField *) aTextField {
	
	self.tripName = aTextField.text;
	self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (BOOL) textFieldShouldBeginEditing:(UITextField *) aTextField {

	if (self.tableView.editing) {
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}
	return self.tableView.editing;
}

#pragma mark -
#pragma mark Memory Management

- (void) dealloc {
	
	[list release];
	[tripsCollection release];
	[trip release];
	[managedObjectContext release];
	[tripName release];
	[cellManager release];
	[super dealloc];
}

@end
