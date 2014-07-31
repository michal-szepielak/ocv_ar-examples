#import "CCNodeAR.h"

#import "Tools.h"

@implementation CCNodeAR

@synthesize objectId;
@synthesize arTranslationVec;
@synthesize scaleZ = _scaleZ;

#pragma mark init/dealloc

-(id)init {
    self = [super init];
    if (self) {
        _scaleZ = 1.0f;
    }
    
    return self;
}

#pragma mark public methods

-(void)setARTransformMatrix:(const float [16])m {
    memcpy(arTransformMat, m, 16 * sizeof(float));
    arTransformGLKMat = GLKMatrix4MakeWithArray(arTransformMat);
}

-(const GLKMatrix4 *)arTransformMatrixPtr {
    return &arTransformGLKMat;
}

#pragma mark parent methods

-(void)setScale:(float)scale {
    _scaleZ = scale;
    [super setScale:scale];
}

-(void)visit:(__unsafe_unretained CCRenderer *)renderer parentTransform:(const GLKMatrix4 *)parentTransform
{
	// quick return if not visible. children won't be drawn.
	if (!_visible)
		return;
    
    [self sortAllChildren];
    
    // just use the AR transform matrix directly for this node
    GLKMatrix4 transform = GLKMatrix4Multiply(*parentTransform, arTransformGLKMat);
    
    // additionally apply a scale matrix
	GLKMatrix4 scaleMat = GLKMatrix4MakeScale(_scaleX, _scaleY, _scaleZ);
    transform = GLKMatrix4Multiply(transform, scaleMat);
    
//    NSLog(@"CCNodeAR - transform:");
//    [Tools printGLKMat4x4:&transform];
    
	BOOL drawn = NO;
    
	for(CCNode *child in _children){
		if(!drawn && child.zOrder >= 0){
			[self draw:renderer transform:&transform];
			drawn = YES;
		}
        
		[child visit:renderer parentTransform:&transform];
    }
    
	if(!drawn) [self draw:renderer transform:&transform];
    
	// reset for next frame
	_orderOfArrival = 0;
}

- (void) sortAllChildren
{
    // copy&paste from CCNode. necessary because this method was private and is called from
    // visit:parentTransform:
    
	if (_isReorderChildDirty)
	{
        [_children sortUsingSelector:@selector(compareZOrderToNode:)];
        
		//don't need to check children recursively, that's done in visit of each child
        
		_isReorderChildDirty = NO;
        
        [[[CCDirector sharedDirector] responderManager] markAsDirty];
        
	}
}

@end