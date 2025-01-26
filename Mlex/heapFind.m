//
//  heapFind.h
//  Mlex
//
//  Created by Dora Orak on 26.01.2025.
//
#import "SharedHeader.h"
#import "Util.h"


static kern_return_t reader(__unused task_t remote_task, vm_address_t remote_address,  vm_size_t size, void **local_memory) {
    *local_memory = (void *)remote_address;
    return KERN_SUCCESS;
}

static void range_callback(task_t task, void *context, unsigned type, vm_range_t *ranges, unsigned rangeCount) {
    
    if (!context) {
        return;
    }
    
    //NSLog(@"[Mlex] in callback");
    
    NSMutableArray *resultArray = (__bridge NSMutableArray *)(*(void **)context);
    
    int classCount = 0;
    Class *classes = objc_copyClassList(&classCount);
    
    CFMutableSetRef registeredClasses = CFSetCreateMutable(NULL, 0, NULL);
    for (unsigned int i = 0; i < classCount; i++) {
            CFSetAddValue(registeredClasses, (__bridge const void *)(classes[i]));
        }

    for (unsigned int i = 0; i < rangeCount; i++) {
        vm_range_t range = ranges[i];
        
        if(!range.address || range.size == 0) {
            continue;
        }
        
        maybe_id *tryObject = (maybe_id *)range.address;
        Class tryClass = NULL;
        
        #if __arm64e__
        
        extern uint64_t objc_debug_isa_class_mask WEAK_IMPORT_ATTRIBUTE;
        tryClass = (__bridge Class)((void *)((uint64_t)tryObject->isa & objc_debug_isa_class_mask));
        
        #else
                tryClass = tryObject->isa;
        #endif
        
        if (CFSetContainsValue(registeredClasses, (__bridge const void *)(tryClass))) {
            const char* className = class_getName(tryClass);
            if (className) {
                // Create a dictionary with the object address and class name.
                NSDictionary *objectInfo = @{
                    @"objaddr": @(range.address),
                    @"classname": @(className)
                };
                
                // Add the dictionary to the result array.
                [resultArray addObject:objectInfo];
            }
            
        }
        
        
    }
     
    free(classes);
    CFRelease(registeredClasses);

}

void heapFind(void* ptr) {
    vm_address_t *zones = NULL;
    unsigned int zoneCount = 0;
    
    if (malloc_get_all_zones(mach_task_self(), reader, &zones, &zoneCount) == KERN_SUCCESS) {
        
        for (unsigned int i = 0; i < zoneCount; i++) {
            malloc_zone_t *zone = (malloc_zone_t *)zones[i];

            void (*lock_zone)(malloc_zone_t *zone) = zone->introspect->force_lock;
            void (*unlock_zone)(malloc_zone_t *zone) = zone->introspect->force_unlock;

            if (zone->introspect && zone->introspect->enumerator && pointerIsReadable(lock_zone) && pointerIsReadable(unlock_zone)) {
                zone->introspect->enumerator(mach_task_self(), ptr, MALLOC_PTR_IN_USE_RANGE_TYPE, (vm_address_t)zone, reader, &range_callback);
            }
        }
    }
    
    return;
}
