//
//  USShrinkController.m
//  URL Shrink
//
//  Created by Steve on 3/30/09.
//  Copyright 2009 Steve Streza. All rights reserved.
//

#import "USShrinkController.h"

#import <objc/runtime.h>

@implementation USShrinkController

objc_singleton(USShrinkController, sharedShrinkController);

- (NSArray*) subclassesOfClass:(Class)superclass fromCArray:(Class[])classes withCount:(int)count {
	NSMutableArray *array = [NSMutableArray array];
	
	for (int i = 0; i < count; i++) {
		Class subclass = classes[i];
		if (class_getSuperclass(subclass) == superclass
			&& [NSStringFromClass(subclass) hasPrefix:@"NSKVONotifying"] == NO
			/* avoid the autogenerated KVO classes if they ever come up in the future */)
		{
			[array addObject:subclass];
			[array addObjectsFromArray:[self subclassesOfClass:subclass fromCArray:classes withCount:count]];
		}
	}
	
	return array;
}

NSInteger ShrinkerSorter(Class shrinker1, Class shrinker2, void* context) {
	return ([[shrinker1 name] caseInsensitiveCompare:[shrinker2 name]]);
}

-(NSArray *)allShrinkers{
	int count = objc_getClassList(NULL, 0);
	
	Class classes[count];
	objc_getClassList(classes, count);
	
	NSArray *shrinkers = [self subclassesOfClass:[USURLShrinker class] fromCArray:classes withCount:count];
	shrinkers = [shrinkers sortedArrayUsingFunction:ShrinkerSorter context:NULL];
	return shrinkers;
}

- (Class) shrinkerForName:(NSString*)shrinkerName {
	for (Class shrinkerClass in [self allShrinkers]) {
		if ([[shrinkerClass name] isEqualToString:shrinkerName])
			return shrinkerClass;
	}
	return nil;
}

-(USURLShrinker *)shrinker{
	Class shrinkerClass = NULL;
	
	NSArray *shrinkers = [self allShrinkers];
	
	//get the user's preferred class
	NSString *defaultsValue = [[NSUserDefaults standardUserDefaults] stringForKey:kUSShrinkChoiceDefaultsKey];
	shrinkerClass = [self shrinkerForName:defaultsValue];
	if (shrinkerClass){
		NSLog(@"Found user default: %@",defaultsValue);
		shrinkerClass = [self shrinkerForName:defaultsValue];
	}
	
	//if there is none, grab one at random
	if(!shrinkerClass){
		NSUInteger index = 0;
		if(shrinkers.count > 1){

			index = GetRandom(1, [shrinkers count]) - 1;
		}
	
		shrinkerClass = [shrinkers objectAtIndex:index];
	}

	//if it exists, make one
	if(shrinkerClass){
		return [[[shrinkerClass alloc] init] autorelease];
	}else return nil;
}

@end
