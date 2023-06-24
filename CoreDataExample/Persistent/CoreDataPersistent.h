//
//  CorePersistent.h
//  CoreDataPlayground
//
//  Created by son.tieu on 22/06/2023.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MQTTPersistence.h"

NS_ASSUME_NONNULL_BEGIN

@interface CoreDataPersistent : NSObject <MQTTPersistence>
- (void)initializeManagedObjectContext;
- (void)deleteAllFlows;

@end

@interface MqttEntity : NSManagedObject <MqttEntityProtocol>
@end

@interface MqttCoreDataEntity : NSObject <MqttEntityProtocol>
@end

NS_ASSUME_NONNULL_END
