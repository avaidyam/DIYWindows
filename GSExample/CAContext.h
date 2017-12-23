#import <QuartzCore/QuartzCore.h>

@interface CAContext: NSObject

@property BOOL colorMatchUntaggedContent;
@property struct CGColorSpace *colorSpace;
@property(copy) NSString *contentsFormat;
@property(readonly) NSUInteger contextId;
@property NSUInteger displayMask;
@property NSUInteger displayNumber;
@property NSUInteger eventMask;
@property(retain) CALayer *layer;
@property(readonly) NSDictionary *options;
@property int restrictedHostProcessId;
@property(readonly) BOOL valid;

+ (id)objectForSlot:(NSUInteger)arg1;
+ (BOOL)allowsCGSConnections;
+ (void)setAllowsCGSConnections:(BOOL)arg1;
+ (id)contextWithCGSConnection:(NSUInteger)arg1 options:(id)arg2;
+ (void)setClientPort:(NSUInteger)arg1;
+ (id)remoteContextWithOptions:(id)arg1;
+ (id)remoteContext;
+ (id)localContextWithOptions:(id)arg1;
+ (id)localContext;
+ (id)currentContext;
+ (id)allContexts;

- (void)setObject:(id)arg1 forSlot:(NSUInteger)arg2;
- (void)deleteSlot:(NSUInteger)arg1;
- (NSUInteger)createSlot;
- (void)invalidateFences;
- (void)setFence:(NSUInteger)arg1 count:(NSUInteger)arg2;
- (void)setFencePort:(NSUInteger)arg1 commitHandler:(id)arg2;
- (void)setFencePort:(NSUInteger)arg1;
- (NSUInteger)createFencePort;
- (void)invalidate;

@end
