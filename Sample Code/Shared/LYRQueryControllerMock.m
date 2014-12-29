//
//  LYRQueryControllerMock.m
//  LayerUIKit
//
//  Created by Kevin Coleman on 12/8/14.
//
//

#import "LYRQueryControllerMock.h"

@interface LYRQueryControllerMock ()

@property (nonatomic) NSOrderedSet *objects;

@end

@implementation LYRQueryControllerMock

+ (instancetype)initWithQuery:(LYRQuery *)query
{
    return [[self alloc] initWithQuery:query];
}

- (id)initWithQuery:(LYRQuery *)query
{
    self = [super init];
    if (self) {
        _query = query;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(mockObjectsDidChange:)
                                                     name:LYRMockObjectsDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (NSUInteger)numberOfSections
{
    return 1;
}

- (NSUInteger)numberOfObjectsInSection:(NSUInteger)section
{
    return self.objects.count;
}

- (NSUInteger)count
{
    return self.objects.count;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.objects objectAtIndex:indexPath.row];
}

- (NSIndexPath *)indexPathForObject:(id<LYRQueryable>)object
{
    return nil;
}

- (BOOL)execute:(NSError **)error
{
    self.objects = [[LYRMockContentStore sharedStore] fetchObjectsWithClass:self.query.queryableClass predicate:self.query.predicate sortDescriptior:self.query.sortDescriptors];
    return YES;
}

- (void)mockObjectsDidChange:(NSNotification *)notification
{
    NSLog(@"Changes %@", notification);
    [self execute:nil];
    [self.delegate queryControllerWillChangeContent:self];
    for (NSDictionary *change in notification.object) {
        if ([[change valueForKey:LYRMockObjectChangeObjectKey] isKindOfClass:[LYRConversationMock class]]) {
            if (self.query.queryableClass == [LYRConversation class]) {
                [self broadcastChange:change];
            }
        } else {
            if (self.query.queryableClass == [LYRMessage class]) {
                [self broadcastChange:change];
            }
        }
    }
    [self.delegate queryControllerDidChangeContent:self];
}

- (void)broadcastChange:(NSDictionary *)mockObjectChange
{
    id objectMock = [mockObjectChange valueForKey:LYRMockObjectChangeObjectKey];
    LYRObjectChangeType changeType = [[mockObjectChange valueForKey:LYRMockObjectChangeChangeTypeKey] integerValue];
    
    NSUInteger index = [self.objects indexOfObject:objectMock];
    
    switch (changeType) {
        case LYRObjectChangeTypeCreate:
            [self.delegate queryController:self didChangeObject:objectMock atIndexPath:nil forChangeType:LYRQueryControllerChangeTypeInsert newIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
            break;
        case LYRObjectChangeTypeUpdate:
            [self.delegate queryController:self didChangeObject:objectMock atIndexPath:[NSIndexPath indexPathForRow:index inSection:0] forChangeType:LYRQueryControllerChangeTypeUpdate newIndexPath:nil];
            break;
        case LYRObjectChangeTypeDelete:
            [self.delegate queryController:self didChangeObject:objectMock atIndexPath:[NSIndexPath indexPathForRow:index inSection:0] forChangeType:LYRQueryControllerChangeTypeDelete newIndexPath:nil];
            break;
        default:
            break;
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
