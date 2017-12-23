#import <CoreFoundation/CoreFoundation.h>
#import <GraphicsServices/GraphicsServices.h>
#import <CGSInternal/CGSInternal.h>
#import <QuartzCore/QuartzCore.h>

#import "CAContext.h"

// We need to locally declare this since GraphicsServices and CGSInternal don't.
extern CGEventRef CGEventCreateNextEvent(CGSConnectionID);

// Initialize the app and grab our main CGSConnection.
static CGSConnectionID cid = 0;
static CGWindowID wid = 0;

int main(int argc, const char *argv[]) {
    cid = CGSMainConnectionID();
    GSInitialize();
    GSAppInitialize();
    
    // Register a default event callback to handle anything for our CGSWindow.
    GSAppRegisterEventCallBack(^(GSEventRef eventRef) {
        CGEventRef event = GSEventGetCGEvent(eventRef);
        CGEventType type = CGEventGetType(event);
        
        // If the event type does not match or it's for the wrong window, bail.
        if (type != NX_KEYDOWN && type != NX_OMOUSEDOWN && type != NX_OMOUSEUP && type != NX_OMOUSEDRAGGED &&
            type != NX_LMOUSEUP && type != NX_LMOUSEDOWN && type != NX_RMOUSEUP && type != NX_RMOUSEDOWN &&
            type != NX_MOUSEMOVED && type != NX_LMOUSEDRAGGED && type != NX_RMOUSEDRAGGED)
            return;
        int64_t d = CGEventGetIntegerValueField(event, kCGMouseEventWindowUnderMousePointer);
        if (d != wid) return;
        
        // If the window was dragged, match the drag to an on-screen move.
        if (type == NX_LMOUSEDRAGGED) {
            CGRect rect = CGRectMake(0, 0, 0, 0);
            CGSGetScreenRectForWindow(cid, wid, &rect);
            rect.origin.x += CGEventGetIntegerValueField(event, kCGMouseEventDeltaX);
            rect.origin.y += CGEventGetIntegerValueField(event, kCGMouseEventDeltaY);
            CGSMoveWindow(cid, wid, &rect.origin);
        }
        
        // If the window was right-clicked, order it out (close it).
        if (type == NX_RMOUSEUP) {
            CGSOrderWindow(cid, wid, kCGSOrderOut, 0);
        }
        
        // If the window was left-clicked, order it in (show it).
        if (type == NX_LMOUSEUP) {
            CGSOrderWindow(cid, wid, kCGSOrderIn, 0);
        }
    });
    
    CGRect outRect = {0, 0, 0, 0};
    CGSGetDisplayBounds(CGMainDisplayID(), &outRect);
    CGRect rect = CGRectInset(outRect, outRect.size.width / 3.0, outRect.size.height / 3.0);
    
    // Create the region (a CGRect, really) first.
    //CGRect rect = {0, 0, CGImageGetWidth(backgroundImage), CGImageGetHeight(backgroundImage)};
    CGSRegionRef region = NULL;
    CGSNewRegionWithRect(&rect, &region);
    rect.origin = (CGPoint){ 0, 0 }; // to get bounds
    
    // Create a CGSWindow to display above everything.
    CGSNewWindow(cid, kCGSBackingBuffered, 0, 0, region, &wid);
    CGSSetWindowLevel(cid, wid, kCGUtilityWindowLevel);
    
    // Wrap all CALayer-related activities into CATransactions.
    [CATransaction begin]; {
        CAContext *ctx;
        CALayer *layer;
        CGSSurfaceID sid;
        //CGContextRef context;
        
        { // Create the CALayer and its matching CAContext.
            ctx = [CAContext contextWithCGSConnection:cid options:nil];
            layer = [[CALayer alloc] init];
            layer.frame = rect;
            layer.backgroundColor = CGColorCreateGenericRGB(1, 0, 0, 1);
            //layer.contents = (__bridge id)backgroundImage;
            ctx.layer = layer;
        }
        { // Add a CGSSurface to the CGSWindow to host the CALayer.
            CGSAddSurface(cid, wid, &sid);
            CGSSetSurfaceBounds(cid, wid, sid, rect);
            CGSSetSurfaceResolution(cid, wid, sid, 2.0);
            CGSSetSurfaceColorSpace(cid, wid, sid, ctx.colorSpace);
        }
        /*{ // Optional: manually render the layer into the CGSWindow.
            CGContextRef context = CGWindowContextCreate(cid, wid, 0);
            CGContextClearRect(context, rect);
            [layer renderInContext:context];
            CGContextFlush(context);
        }*/
        { // Bind and order the CGSSurface onto the CGSWindow.
            CGSBindSurface(cid, wid, sid, 0x4, 0x0, (unsigned int)ctx.contextId);
            CGSOrderSurface(cid, wid, sid, 0x1, 0x0);
            //CGSOrderSurface is incorrect; param 4 is order (like windows), 5 is the relative surface
            //CGSFlushSurface(cid, wid, sid, 0);
        }
        /*{ // Optional: configure opacity of the window and surface.
            CGSSetWindowOpacity(cid, wid, false);
            CGSSetWindowShadowAndRimParameters(cid, wid, 0.0, 0.0, 0, 0, 0);
            CGSSetSurfaceOpacity(cid, wid, sid, false);
            layer.opacity = 0.5;
        }*/
        [CATransaction begin]; { // Animate something!
            CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
            anim.duration = 10.0;
            anim.toValue = (__bridge id _Nullable)(CGColorCreateGenericRGB(0, 0, 1, 1));
            [layer addAnimation:anim forKey:nil];
        } [CATransaction commit];
    } [CATransaction commit];
    
    // Order the CGSWindow on-screen.
    CGSOrderWindow(cid, wid, kCGSOrderIn, 0);
    
    { // HACK: Set a background event mask so we can listen to CGSConnection events.
        
        CGEventMask keyboardMask = CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp);
        CGEventMask mouseMask = CGEventMaskBit(kCGEventMouseMoved) | CGEventMaskBit(kCGEventLeftMouseDown) |
            CGEventMaskBit(kCGEventRightMouseDown) | CGEventMaskBit(kCGEventLeftMouseUp) |
            CGEventMaskBit(kCGEventRightMouseUp) | CGEventMaskBit(kCGEventLeftMouseDragged);
        
        CGEventMask mask = keyboardMask | mouseMask; //0xffffffff;
        CGSSetWindowEventMask(cid, wid, mask);
        CGSSetBackgroundEventMask(cid, (int)mask);
    }
    
    // Begin the event pump!
    GSAppPushRunLoopMode(kGSEventReceiveRunLoopMode);
    GSAppRun();
    return 0;
}
