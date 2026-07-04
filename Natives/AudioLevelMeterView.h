#import <UIKit/UIKit.h>

@interface AudioLevelMeterView : UIView

- (void)startMonitoring;
- (void)stopMonitoring;
@property(nonatomic, readonly, getter=isMonitoring) BOOL monitoring;

+ (void)setGameRunning:(BOOL)running;
+ (BOOL)gameRunning;

@end
