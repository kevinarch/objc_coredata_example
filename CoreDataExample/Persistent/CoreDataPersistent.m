//
//  CorePersistent.m
//  CoreDataPlayground
//
//  Created by son.tieu on 22/06/2023.
//

#import "CoreDataPersistent.h"

@implementation MqttEntity

@dynamic clientId;
@dynamic topic;
@dynamic messageId;

@end

@interface MqttCoreDataEntity ()

- (MqttCoreDataEntity *)initWithContext:(NSManagedObjectContext *)context addObject:(id<MqttEntityProtocol>)object;
@property NSManagedObjectContext *context;
@property id<MqttEntityProtocol> object;

@end

@implementation MqttCoreDataEntity

@synthesize context;
@synthesize object;

- (MqttCoreDataEntity *)initWithContext:(NSManagedObjectContext *)context addObject:(id<MqttEntityProtocol>)object {
    self = [super init];
    self.context = context;
    self.object = object;
    return self;
}

- (NSString *)clientId {
    __block NSString *_clientId;
    [context performBlockAndWait:^{
        _clientId = self.object.clientId;
    }];
    
    return _clientId;
}

- (void)setClientId:(NSString *)clientId {
    [context performBlockAndWait:^{
        self.object.clientId = clientId;
    }];
}

- (NSString *)topic {
    __block NSString *_topic;
    [context performBlockAndWait:^{
        _topic = self.object.topic;
    }];
    return _topic;
}

- (void)setTopic:(NSString *)topic {
    [context performBlockAndWait:^{
        self.object.topic = topic;
    }];
}

- (NSNumber *)messageId {
    __block NSNumber *_messageId;
    [context performBlockAndWait:^{
        _messageId = self.object.messageId;
    }];
    return _messageId;
}

- (void)setMessageId:(NSNumber *)messageId {
    [context performBlockAndWait:^{
        self.object.messageId = messageId;
    }];
}


@end


@interface CoreDataPersistent ()

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation CoreDataPersistent

- (CoreDataPersistent *)init {
    self = [super init];
    
    return self;
}


- (void)initializeManagedObjectContext {
    [self managedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) {
        @synchronized (self) {
            NSPersistentStoreCoordinator *coordinator = [self createPersistentStoreCoordinator];
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            _managedObjectContext.persistentStoreCoordinator = coordinator;
        }
    }
    return _managedObjectContext;
}



- (void)deleteAllFlows {
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"MQTTFlow"];
        NSBatchDeleteRequest *deleteBatch = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
        
        
        deleteBatch.resultType = NSBatchDeleteResultTypeObjectIDs;
        
        NSError *error = nil;
        NSBatchDeleteResult *batchResult = [self.managedObjectContext executeRequest:deleteBatch error:&error];
        
        if (error) {
            NSLog(@"Error when executing batch delete: %@", error.localizedDescription);
            return;
        }
        
        NSArray *deletedIds = batchResult.result;
        
        if (deletedIds && deletedIds.count > 0) {
            NSDictionary* deleteObjects =  @{
                NSDeletedObjectsKey: deletedIds
            };
            
            [NSManagedObjectContext mergeChangesFromRemoteContextSave:deleteObjects intoContexts:@[self.managedObjectContext]];
        }
    }];
}

- (NSObject *)storeMessageForClientId: (NSString *)clientId topic:(nonnull NSString *)topic msgId:(UInt16)msgId {
    __block id<MqttEntityProtocol> row;
    
    [self.managedObjectContext performBlockAndWait:^{
        row = [NSEntityDescription insertNewObjectForEntityForName:@"MQTTFlow" inManagedObjectContext:self.managedObjectContext];
        
        row.clientId = clientId;
        row.topic = topic;
        row.messageId = @(msgId);
    }];
    
    return [[MqttCoreDataEntity alloc] initWithContext:self.managedObjectContext addObject:row];
}

- (nonnull NSArray *)allFlowsforClientId:(nonnull NSString *)clientId{
    NSMutableArray *flows = [NSMutableArray array];
    __block NSArray *rows;
    
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MQTTFlow"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"clientId = %@", clientId];
        
        NSError* error;
        rows = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (!rows) {
            NSLog(@"Failed to execute fetchRequest: %@", error.localizedDescription);
        }
        if (error) {
            NSLog(@"Error allFlowsforClientId %@", error.localizedDescription);
        }
    }];
    
    for (id<MqttEntityProtocol>row in rows) {
        [flows addObject:[[MqttCoreDataEntity alloc] initWithContext:self.managedObjectContext addObject:row]];
    }
    
    return flows;
}


- (void)deleteAllFlowsForClientId:(nonnull NSString *)clientId { 
    [self.managedObjectContext performBlockAndWait:^{
        for (MqttCoreDataEntity *flow in [self allFlowsforClientId:clientId]) {
            [self.managedObjectContext deleteObject:(NSManagedObject *)flow.object];
        }
    }];
}


- (NSPersistentStoreCoordinator *)createPersistentStoreCoordinator {
    NSURL* applicationDocumentDir = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
    NSURL *persistentStoreURL = [applicationDocumentDir URLByAppendingPathComponent: @"MQTT"];
    
    NSManagedObjectModel *model = [self createManagedObjectModel];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    NSDictionary *options = @{
        NSMigratePersistentStoresAutomaticallyOption: @YES,
        NSInferMappingModelAutomaticallyOption: @YES,
        NSSQLiteAnalyzeOption: @YES,
        NSSQLiteManualVacuumOption: @YES
    };
    
    NSError *error = nil;
    
    [coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:persistentStoreURL options:options error:&error];
    
    if (error) {
        NSLog(@"Failed to create persistent store with SQLite %@", error.localizedDescription);
        coordinator = nil;
    }
    
    return coordinator;
}

- (NSManagedObjectModel *)createManagedObjectModel {
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] init];
    NSMutableArray *entities = [[NSMutableArray alloc] init];
    NSMutableArray *properties = [[NSMutableArray alloc] init];
    
    NSAttributeDescription *attributeDescription;
    
    attributeDescription = [[NSAttributeDescription alloc] init];
    attributeDescription.name = @"clientId";
    attributeDescription.attributeType = NSStringAttributeType;
    attributeDescription.attributeValueClassName = @"NSString";
    [properties addObject:attributeDescription];
    
    attributeDescription = [[NSAttributeDescription alloc] init];
    attributeDescription.name = @"messageId";
    attributeDescription.attributeType = NSInteger32AttributeType;
    attributeDescription.attributeValueClassName = @"NSNumber";
    [properties addObject:attributeDescription];
    
    attributeDescription = [[NSAttributeDescription alloc] init];
    attributeDescription.name = @"topic";
    attributeDescription.attributeType = NSStringAttributeType;
    attributeDescription.attributeValueClassName = @"NSString";
    [properties addObject:attributeDescription];
    
    NSEntityDescription *entityDescription = [[NSEntityDescription alloc] init];
    entityDescription.name = @"MQTTFlow";
    entityDescription.managedObjectClassName = @"MqttEntity";
    entityDescription.abstract = FALSE;
    entityDescription.properties = properties;
    
    [entities addObject:entityDescription];
    managedObjectModel.entities = entities;
    
    return managedObjectModel;
}


@end
