//
//  AddTripController.m
//  Jaunt
//
//  Created by John Bowles on 10/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AddTripController.h"
#import "Trip.h"
#import "Photo.h"
#import "JauntAppDelegate.h"
#import	"CellManager.h"
#import "IndexedTextField.h"
#import	"TextFieldExtension.h"
#import "CellExtension.h"
#import	"Logger.h"
#import "UIImage+Extension.h"
#import "ActivityManager.h"

@implementation AddTripController


@synthesize activityManager;
@synthesize trip;
@synthesize tripName;
@synthesize cellManager;
@synthesize photoButton;


#pragma mark -
#pragma mark View Management

- (void)viewDidLoad {
	
	[super viewDidLoad];
	
	ActivityManager *anActivityManager = [[ActivityManager alloc] initWithView:self.tableView];
	self.activityManager = anActivityManager;
	[anActivityManager release];
	
	UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
	self.navigationItem.rightBarButtonItem = saveButton;
	self.navigationItem.rightBarButtonItem.enabled = NO;
	[saveButton release];
	
	[self createHeader];
	[self loadCells];
}

-(void) createHeader {
	
	CGRect aFrame = CGRectMake(20, 18, 62, 62);
	
	UIImage *anImage = [UIImage imageNamed:@"GenericContact.png"];
	UIButton *aButton = [[UIButton alloc] initWithFrame:aFrame];
	[aButton setBackgroundImage:anImage forState:UIControlStateNormal];
	aButton.titleLabel.font = [UIFont systemFontOfSize: 12];
	[aButton setTitle:@"add photo" forState:UIControlStateNormal];
	[aButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[aButton addTarget:self action:@selector(setTripImage:) forControlEvents:UIControlEventTouchUpInside];
	[self setPhotoButton:aButton];
	
	aFrame = CGRectMake(0, 0, self.tableView.bounds.size.width, 100);
	UIView *aHeaderView = [[UIView alloc] initWithFrame:aFrame];
	[aHeaderView addSubview:aButton];
	aHeaderView.backgroundColor = [UIColor clearColor];
	self.tableView.tableHeaderView = aHeaderView;	
	
	[aHeaderView release];
	[aButton release];
}

#pragma mark -
#pragma mark Camera

- (void) setTripImage:(id) sender {
	
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
		
		UIImagePickerController *aPicker = [[UIImagePickerController alloc] init];
		aPicker.delegate = self;
		aPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		[self presentModalViewController:aPicker animated:YES];
		
		[aPicker release];
	}
}

- (void) imagePickerController:(UIImagePickerController *) aPicker didFinishPickingImage:(UIImage *)anImage editingInfo:(NSDictionary *) editingInfo {
	
	[[self photoButton] setBackgroundImage:anImage forState:UIControlStateNormal];
	[[self photoButton] setTitle:nil forState:UIControlStateNormal];
	
	Photo *aPhoto = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext: self.trip.managedObjectContext];
	aPhoto.image = anImage;
	
	self.trip.photo = aPhoto;
	self.trip.thumbNail = [UIImage imageWithImage:anImage scaledToSize:CGSizeMake(88.0, 66.0)];
	 
	[aPicker dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *) aPicker {
	
	[aPicker dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Cell Management Methods

- (void) loadCells {
	
	NSArray *nibNames = [NSArray arrayWithObjects:@"TextFieldCell", nil];
	NSArray *identifiers = [NSArray arrayWithObjects:@"TextFieldCell", nil];
	
	CellManager *manager = [[CellManager alloc] initWithNibs:nibNames withIdentifiers:identifiers forOwner:self];
	self.cellManager = manager;
	
	[manager release];
}

#pragma mark -
#pragma mark Persistence

- (void) save {
	
	[self.activityManager startTaskWithTarget:self selector:@selector(asyncSave) object:nil];
}

- (void) asyncSave {
		
	NSAutoreleasePool *aPool = [[NSAutoreleasePool alloc] init];
	
	JauntAppDelegate *aDelegate = [[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *aContext = [aDelegate managedObjectContext];
	
	[self.trip setName: self.tripName];
	
	NSError *error;
	
	if (![aContext save: &error]) {
		
		[Logger logError:error withMessage:@"Failed to add trip"];
	}
	
	[self performSelectorOnMainThread:@selector(finishedSaving) withObject:nil waitUntilDone:NO]; 
	
	[aPool release];
}

-(void) finishedSaving {

	[self.activityManager stopTask];
	
	JauntAppDelegate *aDelegate = [[UIApplication sharedApplication] delegate];
	UINavigationController *aController = [aDelegate navigationController];
	[aController popViewControllerAnimated:YES];

}

#pragma mark -
#pragma mark Table Data Source Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	return 1;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
	static NSString *reuseIdentifer = @"TextFieldCell";
	UITableViewCell *cell = (UITableViewCell *) [tableView dequeueReusableCellWithIdentifier: reuseIdentifer];
	
	if (cell == nil) {
		
		cell = [self.cellManager cellForSection:indexPath.section];
		UITextField *aField = [cell indexedTextField];
		[aField setIndexPathForField: indexPath];
	}
	
	[cell setCellExtensionDelegate:self];
	[cell setTitleForCell: @"Name:"];
	
	return cell;
}

#pragma mark -
#pragma mark Text Field Delegate Methods

- (void) textFieldDidBeginEditing:(UITextField *) textField
{
	self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void) textFieldDidEndEditing:(UITextField *) aTextField {
	
	[self setTripName:aTextField.text];
	self.navigationItem.rightBarButtonItem.enabled = YES;
}

#pragma mark -
#pragma mark Memory Management

- (void) dealloc {
	
	[activityManager release];
	[trip release];
	[tripName release];
	[cellManager release];
	[photoButton release];
	[super dealloc];
}

@end
