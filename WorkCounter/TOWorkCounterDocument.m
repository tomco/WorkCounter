//
//  TOWorkCounterDocument.m
//  WorkCounter
//
//  Created by Tobias Ottenweller on 4/17/11.
//
//

#import "TOWorkCounterDocument.h"
#import "TOWorkIntervall.h"

@implementation TOWorkCounterDocument

- (id)init
{
    self = [super init];
    
    if (self) 
        intervalls = [[NSMutableArray alloc] init];
    
    return self;
}


- (void)dealloc
{
    [intervalls release];
    
    [super dealloc];
}


- (NSString *)windowNibName
{
    return @"TOWorkCounterDocument";
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    [tableView reloadData];
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError 
{
    if (currentIntervall)
        [self beginEndIntervall:nil];
    
    return [NSKeyedArchiver archivedDataWithRootObject:intervalls];
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError 
{
    NSMutableArray *newArray = nil;
    
    @try 
    {
        newArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    @catch (NSException *exception) 
    {
        if (outError) 
        {
            NSDictionary *dic = [NSDictionary dictionaryWithObject:@"The data is corrupted." forKey:NSLocalizedFailureReasonErrorKey];
            *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:dic];
        }
        return NO;
    }

    intervalls = [newArray retain];
    
    return YES;
}


- (NSString *)totalTime
{
    unsigned long totalTime = 0;
    
    for (TOWorkIntervall *i in intervalls)
        totalTime += i.timeWorked;
    
    if (currentIntervall)
        totalTime += currentIntervall.timeWorked;
    
    return [TOWorkIntervall secondsToString:totalTime];
}


- (NSString *)currentTime 
{
    unsigned long totalTime = 0;
    if (currentIntervall)
        totalTime = currentIntervall.timeWorked;
    
    return [TOWorkIntervall secondsToString:totalTime];
}


- (IBAction)beginEndIntervall:(id)sender 
{
    [self updateChangeCount:NSChangeDone];
    
    if (currentIntervall) 
    {
        [timer invalidate];
        [timer release];
        
        [currentIntervall end];
        [intervalls addObject:currentIntervall];
        [currentIntervall release];
        currentIntervall = nil;
        
        [tableView reloadData];
        
    } 
    else 
    {
        currentIntervall = [[TOWorkIntervall alloc] init];
        [currentIntervall start];

        timer = [[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(syncUI) userInfo:nil repeats:YES] retain];
        [timer fire];
    }
}


- (IBAction)safeAsCSV:(id)sender 
{
    NSSavePanel *sp = [NSSavePanel savePanel];
    
    [sp beginSheetModalForWindow:[tableView window] 
                 completionHandler:^(NSInteger result) 
                    {
                         if (result != NSOKButton)
                             return;
                         
                         NSString *csv = [TOWorkIntervall intervallsToCSV:intervalls];
                         NSError *error;
                         
                         BOOL success =[csv writeToURL:[sp URL] atomically:YES 
                                              encoding:NSUTF8StringEncoding 
                                                 error:&error];
                         
                         if (!success) 
                         {
                             NSAlert *alert = [NSAlert alertWithError:error];
                             [alert runModal];
                         }
                         
                     }];
}


- (void)syncUI
{    
    [self willChangeValueForKey:@"currentTime"];
    [self didChangeValueForKey:@"currentTime"];
    
    [self willChangeValueForKey:@"totalTime"];
    [self didChangeValueForKey:@"totalTime"];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [intervalls count];
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSString *identifier = [aTableColumn identifier];
    id returnValue = @"";
    
    
    if ([identifier isEqual:@"dateColumn"] || [identifier isEqual:@"startColumn"])
        
        returnValue = [[intervalls objectAtIndex:rowIndex] startDate];
    
    else if ([identifier isEqual:@"endColumn"])
        
        returnValue = [[intervalls objectAtIndex:rowIndex] endDate];
    
    else if ([identifier isEqual:@"timeColumn"])
    {
        unsigned long totalTime = [[intervalls objectAtIndex:rowIndex] timeWorked];
        
        returnValue = [TOWorkIntervall secondsToString:totalTime];
    }
    
    else if ([[aTableColumn identifier] isEqual:@"Comment"])
        
        returnValue = [[intervalls objectAtIndex:rowIndex] comment];
    
    return returnValue;
}


- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if ([[aTableColumn identifier] isEqual:@"Comment"])
        [[intervalls objectAtIndex:rowIndex] setComment:anObject];
}


@end
