//
//  AllSongsTVC.m
//  TuneFlow
//
//  Created by Ben Goldberger on 12/24/13.
//  Copyright (c) 2013 Ben Goldberger. All rights reserved.
//

#import "AllSongsTVC.h"
#import "Song.h"
#import "MediaPlayerVC.h"

@interface AllSongsTVC ()

@end

@implementation AllSongsTVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _selectedSongs = [[NSMutableArray alloc]init];
    UIBarButtonItem *btnSave = [[UIBarButtonItem alloc]
                                initWithTitle:@"Use Selected Songs"
                                style:UIBarButtonItemStyleDone
                                target:self
                                action:@selector(startMediaPlayer)];
    self.navigationItem.rightBarButtonItem = btnSave;
    //self.navigationController.navigationBar.

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.dataSource = self;
}

-(IBAction)startMediaPlayer{//:(id)sender{
    [self.blueComm setupTransfer:1];
}
-(void)transferComplete:(BOOL)successful{
    if (successful){
        MediaPlayerVC *vc =[self.storyboard instantiateViewControllerWithIdentifier:@"MediaPlayer"];
        [vc setPlaylist: self.finalPlaylist];
        [vc setBlueComm: self.blueComm];
        self.blueComm.delegate = vc;
        [self.navigationController pushViewController:vc animated:true];
    }
    else{
        NSLog(@"ERROR: Transfer was not successful");
    }
}
-(NSData *)getFirstData{
    if (self.selectedSongs > 0){
        return [NSKeyedArchiver archivedDataWithRootObject:self.selectedSongs];
    }
    else{
        NSLog(@"ERROR: Must pick at least one song");
        return nil;
    }
}
-(void)processFirstData:(NSData *)data{
    //TODO...logic for switch their songs with our songs
    //now it just appends to end
    NSMutableArray *finalPlaylist = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    //initalize with their songs
    //for (Song *song in self.selectedSongs){
    for (NSString *title in self.selectedSongs){
        //[finalPlaylist addObject:song];
        [finalPlaylist addObject:title];
    }
    self.finalPlaylist = finalPlaylist;
}
-(NSData *)getSecondData{
    return [NSKeyedArchiver archivedDataWithRootObject:self.finalPlaylist];
}
-(void)processSecondData:(NSData *)data{
    self.finalPlaylist = (NSArray *) [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

-(void)setSharedSongs:(NSArray *)sharedSongs{
    _sharedSongs = [[NSArray alloc] initWithArray:sharedSongs];
    [self.tableView reloadData];
}
-(void)setBlueComm:(BlueCommModel *)blueComm{
    _blueComm = blueComm;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.sharedSongs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SongCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    Song *song = [self.sharedSongs objectAtIndex:(indexPath.row)];
    [cell.textLabel setText: (NSString *)[song title]];
    [cell.detailTextLabel setText:(NSString *)[song artist]];
    
    //Make sure check mark is correct when dequeueing (also have to do on select, but this fixes problem where check appears multiple times when one cell is pressed)

    //if ([self.selectedSongs containsObject:song]){
    if ([self.selectedSongs containsObject:[song title]]){
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
    }
    else{
        cell.accessoryType = UITableViewCellAccessoryNone;
        
    }
    // Configure the cell...
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    Song *song = [self.sharedSongs objectAtIndex:indexPath.row];
    
    //if ([self.selectedSongs containsObject:song]){
    //    [self.selectedSongs removeObject:song];
    if ([self.selectedSongs containsObject:[song title]]){
        [self.selectedSongs removeObject:[song title]];
        cell.accessoryType = UITableViewCellAccessoryNone;

    }
    else{
        //[self.selectedSongs addObject:song];
        [self.selectedSongs addObject:[song title]];

        cell.accessoryType = UITableViewCellAccessoryCheckmark;

    }
}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
