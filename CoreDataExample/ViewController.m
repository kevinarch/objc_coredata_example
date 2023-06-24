//
//  ViewController.m
//  CoreDataPlayground
//
//  Created by son.tieu on 22/06/2023.
//

#import "ViewController.h"
#import "Persistent/CoreDataPersistent.h"
#include <stdlib.h>

@interface ViewController ()
@end

@implementation ViewController {
    CoreDataPersistent *_store;
}

NSString* _clientId = @"tung87-5g85gh-578n6";
NSString* _topic = @"/example_topic";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _store = [CoreDataPersistent alloc];
    [_store initializeManagedObjectContext];
}

- (IBAction)onTapDeleteAllFlows:(id)sender {
    [_store deleteAllFlows];
}

- (IBAction)onTapDeleteAllFlowsClientId:(id)sender {
    [_store deleteAllFlowsForClientId:_clientId];
}

- (IBAction)onTapStoreRandomDataRow:(id)sender {
    UInt16 randomValue = (UInt16)arc4random_uniform(UINT16_MAX + 1);
    [_store storeMessageForClientId:_clientId topic:_topic msgId:randomValue];
}


@end
