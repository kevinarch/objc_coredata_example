//
//  MQTTPersistence.h
//  CoreDataPlayground
//
//  Created by son.tieu on 23/06/2023.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@protocol MqttEntityProtocol <NSObject>

@property (strong, nonatomic) NSString *clientId;
@property (strong, nonatomic) NSString *topic;
@property (strong, nonatomic) NSNumber *messageId;

@end

@protocol MQTTPersistence


- (NSArray *)allFlowsforClientId:(NSString *)clientId;
- (void)deleteAllFlowsForClientId:(NSString *)clientId;

- (id<MqttEntityProtocol>)storeMessageForClientId:(NSString *)clientId
                                  topic:(NSString *)topic
                                  msgId:(UInt16)msgId;

@end



NS_ASSUME_NONNULL_END
