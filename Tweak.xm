#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <objc/runtime.h>
#import "RegTelTweak-Swift.h"

// RegTel Tweak v1.0.7 - High Stability build for Jailed iOS 17 (C-hooks & UIFont swizzles disabled for boot safety)
#import <sqlite3.h>

// Declarations of Telegram classes to avoid compiler warnings
@interface TelegramUI_ItemListController : UIViewController
- (NSString *)title;
@end

@interface TelegramUI_ChatController : UIViewController
- (int64_t)getChatId;
@end

@interface MTRequest : NSObject
@property (nonatomic, strong) id body;
@end

@interface ASTextNode : NSObject
- (void)setAttributedText:(NSAttributedString *)attributedText;
@end

@interface Message : NSObject
@property (nonatomic) int32_t ttl;
@end

@interface StoreMessage : NSObject
@property (nonatomic) int32_t ttl;
@end

// Static variables for caching preferences
static BOOL isAntiRecallActive = NO;
static BOOL isGhostMaster = NO;
static BOOL isGhostNoRead = NO;
static BOOL isGhostNoTyping = NO;
static BOOL isGhostNoOnline = NO;
static BOOL isGhostStories = NO;
static BOOL isScreenshotUnblock = NO;
static BOOL isHideContactsTab = NO;
static BOOL isHideStoriesTab = NO;
static BOOL isStreamerMode = NO;
static NSString *profileBadge = nil;
static NSString *activeFont = nil;

static void updatePreferences() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    isAntiRecallActive = [defaults boolForKey:@"regress_antirecall_active"];
    isGhostMaster = [defaults boolForKey:@"regress_ghost_master"];
    isGhostNoRead = [defaults boolForKey:@"regress_ghost_noread"];
    isGhostNoTyping = [defaults boolForKey:@"regress_ghost_notyping"];
    isGhostNoOnline = [defaults boolForKey:@"regress_ghost_noonline"];
    isGhostStories = [defaults boolForKey:@"regress_ghost_stories"];
    isScreenshotUnblock = [defaults boolForKey:@"regress_unblock_screenshots"];
    isHideContactsTab = [defaults boolForKey:@"regress_hide_contacts_tab"];
    isHideStoriesTab = [defaults boolForKey:@"regress_hide_stories_tab"];
    isStreamerMode = [defaults boolForKey:@"regress_streamer_mode"];
    profileBadge = [defaults stringForKey:@"regress_profile_badge"];
    activeFont = [defaults stringForKey:@"regress_active_font"];
}

// Thread-safe preferences loader
static BOOL isLoadingPreferences = NO;
static BOOL preferencesLoaded = NO;

static void ensurePreferencesLoaded() {
    if (preferencesLoaded) return;
    
    if (![NSThread isMainThread]) {
        return;
    }
    
    @synchronized([NSUserDefaults class]) {
        if (preferencesLoaded || isLoadingPreferences) return;
        isLoadingPreferences = YES;
        updatePreferences();
        preferencesLoaded = YES;
        isLoadingPreferences = NO;
    }
}

// MARK: - Helper Functions for Anti-Recall Hooking (Temporarily commented out for boot safety)
/*
static BOOL shouldBlockSqlDeleteQuery(const char *zSql) {
    if (zSql == NULL) return NO;
    
    const char *deleteQueries[] = {
        "DELETE FROM messages",
        "delete_message",
        "DELETE FROM message_history",
        "delete_message_history"
    };
    
    for (int i = 0; i < 4; i++) {
        if (strstr(zSql, deleteQueries[i]) != NULL) {
            return YES;
        }
    }
    return NO;
}

static void handleBlockedSqlMessageDeletion(const char *zSql) {
    NSLog(@"[RegTel] Anti-Recall: Blocked local SQLite message deletion: %s", zSql);
    
    long long msgId = 0;
    const char *p = zSql;
    while (*p) {
        if (isdigit(*p)) {
            long long val = 0;
            int digitCount = 0;
            while (isdigit(*p)) {
                val = val * 10 + (*p - '0');
                p++;
                digitCount++;
            }
            if (digitCount >= 5 && digitCount <= 20) {
                msgId = val;
                break;
            }
        } else {
            p++;
        }
    }
    
    if (msgId != 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[AyuMessageTracker shared] registerDetailedMessageDeletionWithMessageId:msgId 
                                                                           chatId:12345 
                                                                       senderName:@"Собеседник" 
                                                                             text:@"[Удаленное сообщение]" 
                                                                             date:(int32_t)[[NSDate date] timeIntervalSince1970]];
        });
    }
}
*/


// MARK: - Hook: Ingesting Regress Settings into Main Telegram Settings

%group TelegramUIHooks

%hook TelegramUI_ItemListController

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    
    // Check if the current controller is the main settings screen
    NSString *title = [self title];
    if ([title isEqualToString:@"Settings"] || 
        [title isEqualToString:@"Настройки"] || 
        [title isEqualToString:@"Settings.Title"]) {
        
        // Add a gorgeous, glowing native-looking button "Regress ⚙️" in the top right
        UIBarButtonItem *regressItem = [[UIBarButtonItem alloc] initWithTitle:@"Regress ⚙️" 
                                                                        style:UIBarButtonItemStyleDone 
                                                                        target:self 
                                                                        action:@selector(openRegressSettingsPanel)];
        
        // Set glowing Material 3 cyan brand color
        regressItem.tintColor = [UIColor systemTealColor];
        [[self navigationItem] setRightBarButtonItem:regressItem];
    }
}

%new
- (void)openRegressSettingsPanel {
    RegressSettingsViewController *settingsVC = [[RegressSettingsViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    [self presentViewController:nav animated:YES completion:nil];
}

%end

// MARK: - Hook: Chat Controller (Adds a Trash Button 🗑️ to view deleted chat history)

%hook TelegramUI_ChatController

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    
    // Extract unique chatId / peerId dynamically
    int64_t chatId = 0;
    if ([self respondsToSelector:@selector(peerId)]) {
        // Safe dynamically resolved access to peerId
        Ivar peerIdIvar = class_getInstanceVariable([self class], "peerId");
        if (peerIdIvar) {
            chatId = *(int64_t *)((char *)(__bridge void *)self + ivar_getOffset(peerIdIvar));
        } else {
            chatId = (int64_t)[self performSelector:@selector(peerId)];
        }
    }
    
    if (chatId == 0) {
        // Fallback to controller hash as identifier
        chatId = (int64_t)[self hash];
    }
    
    // Associate the chatId for recovery inside click handlers
    objc_setAssociatedObject(self, @selector(getChatId), @(chatId), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // Add custom trash bin button if the chat has deleted messages
    if ([[AyuMessageTracker shared] hasDeletedMessagesForChatId:chatId]) {
        UIBarButtonItem *trashBtn = [[UIBarButtonItem alloc] initWithTitle:@"🗑️" 
                                                                      style:UIBarButtonItemStylePlain 
                                                                     target:self 
                                                                     action:@selector(openDeletedHistoryPanel)];
        trashBtn.tintColor = [UIColor systemRedColor];
        [[self navigationItem] setRightBarButtonItem:trashBtn];
    }
}

%new
- (int64_t)getChatId {
    NSNumber *val = objc_getAssociatedObject(self, @selector(getChatId));
    return val ? [val longLongValue] : 0;
}

%new
- (void)openDeletedHistoryPanel {
    int64_t chatId = [self getChatId];
    RegressDeletedHistoryViewController *historyVC = [[RegressDeletedHistoryViewController alloc] init];
    historyVC.chatId = chatId;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:historyVC];
    [self presentViewController:nav animated:YES completion:nil];
}

%end

%end

// MARK: - Hook: Ghost Mode, Screenshots & Stories (MTProto Network Layer)

%group MTProtoHooks

%hook MTProto

- (void)enqueueRequest:(MTRequest *)request {
    ensurePreferencesLoaded();
    NSString *requestType = NSStringFromClass([request.body class]);
    
    // 1. Ghost Mode
    if (isGhostMaster) {
        if (isGhostNoRead) {
            if ([requestType containsString:@"messages_readHistory"] || 
                [requestType containsString:@"channels_readHistory"] ||
                [requestType containsString:@"readMentions"] ||
                [requestType containsString:@"readStories"]) {
                NSLog(@"[RegTel] Ghost Mode: Blocked outgoing read receipt: %@", requestType);
                return; // Drop!
            }
        }
        
        if (isGhostNoTyping) {
            if ([requestType containsString:@"messages_setTyping"] || 
                [requestType containsString:@"channels_setTyping"]) {
                NSLog(@"[RegTel] Ghost Mode: Blocked outgoing typing status: %@", requestType);
                return; // Drop!
            }
        }
        
        if (isGhostNoOnline) {
            if ([requestType containsString:@"account_updateStatus"]) {
                NSLog(@"[RegTel] Ghost Mode: Blocked outgoing online status update: %@", requestType);
                return; // Drop!
            }
        }
    }
    
    // 2. Ghost Stories (Anonymous stories view)
    if (isGhostStories) {
        if ([requestType containsString:@"stories_readStories"] || 
            [requestType containsString:@"readStories"]) {
            NSLog(@"[RegTel] Stories: Blocked stories read notification: %@", requestType);
            return; // Drop!
        }
    }
    
    // 3. Screenshot Unblocker (Block notification to server)
    if (isScreenshotUnblock) {
        if ([requestType containsString:@"sendScreenshotNotification"] || 
            [requestType containsString:@"messages_sendScreenshotNotification"]) {
            NSLog(@"[RegTel] Screenshot: Blocked screenshot notification to server: %@", requestType);
            return; // Drop!
        }
    }
    
    %orig(request);
}

%end

%end

// MARK: - Hook: Anti-Recall (Temporarily disabled for iOS 17 Boot Stability)
/*
%hookf(int, sqlite3_prepare_v2, sqlite3 *db, const char *zSql, int nByte, sqlite3_stmt **ppStmt, const char **pzTail) {
    ensurePreferencesLoaded();
    if (zSql != NULL && isAntiRecallActive && shouldBlockSqlDeleteQuery(zSql)) {
        handleBlockedSqlMessageDeletion(zSql);
        *ppStmt = NULL;
        return SQLITE_OK;
    }
    return %orig(db, zSql, nByte, ppStmt, pzTail);
}

%hookf(int, sqlite3_prepare_v3, sqlite3 *db, const char *zSql, int nByte, unsigned int prepFlags, sqlite3_stmt **ppStmt, const char **pzTail) {
    ensurePreferencesLoaded();
    if (zSql != NULL && isAntiRecallActive && shouldBlockSqlDeleteQuery(zSql)) {
        handleBlockedSqlMessageDeletion(zSql);
        *ppStmt = NULL;
        return SQLITE_OK;
    }
    return %orig(db, zSql, nByte, prepFlags, ppStmt, pzTail);
}
*/

// MARK: - Hook: Tab Bar Navigation customizer

%hook UITabBarController

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated {
    ensurePreferencesLoaded();
    NSMutableArray *mutableVCs = [viewControllers mutableCopy];
    NSMutableArray *toRemove = [NSMutableArray array];
    
    for (UIViewController *vc in mutableVCs) {
        NSString *className = NSStringFromClass([vc class]);
        
        if (isHideContactsTab) {
            if ([className containsString:@"Contacts"] || [className containsString:@"ContactList"]) {
                [toRemove addObject:vc];
            }
        }
        
        if (isHideStoriesTab) {
            if ([className containsString:@"Story"] || [className containsString:@"Call"] || [className containsString:@"Stories"]) {
                [toRemove addObject:vc];
            }
        }
    }
    
    [mutableVCs removeObjectsInArray:toRemove];
    %orig([mutableVCs copy], animated);
}

%end

// MARK: - Hook: Screenshot Unblocker (System screen capture bypass)

%hook UIScreen
- (BOOL)isCaptured {
    ensurePreferencesLoaded();
    if (isScreenshotUnblock) {
        return NO; // Tricking iOS to believe screen is not recording
    }
    return %orig;
}
%end

// MARK: - Hook: Streamer Mode & Custom Profile Badges (ASTextNode)

%group ASTextNodeHooks

%hook ASTextNode

- (void)setAttributedText:(NSAttributedString *)attributedText {
    ensurePreferencesLoaded();
    if (attributedText != nil) {
        NSString *string = [attributedText string];
        NSMutableAttributedString *mutableCopy = [attributedText mutableCopy];
        BOOL modified = NO;
        
        // 1. Streamer Mode Masking
        if (isStreamerMode) {
            NSRegularExpression *phoneRegex = [NSRegularExpression regularExpressionWithPattern:@"\\+[0-9]{10,15}" options:0 error:nil];
            NSRegularExpression *usernameRegex = [NSRegularExpression regularExpressionWithPattern:@"@[a-zA-Z0-9_]{3,32}" options:0 error:nil];
            
            NSArray *phoneMatches = [phoneRegex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
            for (NSTextCheckingResult *match in [phoneMatches reverseObjectEnumerator]) {
                [mutableCopy replaceCharactersInRange:match.range withString:@"+***********"];
                modified = YES;
            }
            
            NSArray *usernameMatches = [usernameRegex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
            for (NSTextCheckingResult *match in [usernameMatches reverseObjectEnumerator]) {
                [mutableCopy replaceCharactersInRange:match.range withString:@"@******"];
                modified = YES;
            }
        }
        
        // 2. Custom Profile Badges Injection
        if (profileBadge != nil && ![profileBadge isEqualToString:@"Без значка"]) {
            NSString *badgeChar = @"";
            if ([profileBadge containsString:@"👑"]) badgeChar = @" 👑";
            else if ([profileBadge containsString:@"🛡️"]) badgeChar = @" 🛡️";
            else if ([profileBadge containsString:@"👻"]) badgeChar = @" 👻";
            else if ([profileBadge containsString:@"⚡"]) badgeChar = @" ⚡";
            else if ([profileBadge containsString:@"⭐"]) badgeChar = @" ⭐";
            
            if ([string isEqualToString:@"You"] || [string isEqualToString:@"Избранное"] || [string isEqualToString:@"Saved Messages"] || [string isEqualToString:@"Regress"]) {
                [mutableCopy appendAttributedString:[[NSAttributedString alloc] initWithString:badgeChar attributes:[attributedText attributesAtIndex:0 effectiveRange:NULL]]];
                modified = YES;
            }
        }
        
        if (modified) {
            %orig([mutableCopy copy]);
            return;
        }
    }
    %orig(attributedText);
}

%end

%end

// MARK: - Hook: Custom Font Customizer (UIFont Swizzling - Temporarily disabled for layout compatibility)
/*
%hook UIFont

+ (UIFont *)fontWithName:(NSString *)fontName size:(CGFloat)fontSize {
    ensurePreferencesLoaded();
    NSString *customFont = activeFont;
    if (customFont != nil && ![customFont isEqualToString:@"Системный"]) {
        UIFont *font = %orig(customFont, fontSize);
        if (font != nil) {
            return font;
        }
    }
    return %orig(fontName, fontSize);
}

+ (UIFont *)systemFontOfSize:(CGFloat)fontSize {
    ensurePreferencesLoaded();
    NSString *customFont = activeFont;
    if (customFont != nil && ![customFont isEqualToString:@"Системный"]) {
        UIFont *font = [UIFont fontWithName:customFont size:fontSize];
        if (font != nil) {
            return font;
        }
    }
    return %orig(fontSize);
}

+ (UIFont *)boldSystemFontOfSize:(CGFloat)fontSize {
    ensurePreferencesLoaded();
    NSString *customFont = activeFont;
    if (customFont != nil && ![customFont isEqualToString:@"Системный"]) {
        NSString *boldFontName = [customFont stringByAppendingString:@"-Bold"];
        UIFont *font = [UIFont fontWithName:boldFontName size:fontSize];
        if (font == nil) {
            font = [UIFont fontWithName:customFont size:fontSize];
        }
        if (font != nil) {
            return font;
        }
    }
    return %orig(fontSize);
}

%end
*/

// MARK: - Hook Initialization & Dynamic Class Resolver

%ctor {
    // Listen for preference changes to update the cache dynamically
    [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      @synchronized([NSUserDefaults class]) {
                                                          updatePreferences();
                                                      }
                                                  }];
    
    // 1. Initialize MTProtoHooks if MTProto class is resolved
    Class mtProtoClass = objc_getClass("MTProto");
    if (mtProtoClass) {
        %init(MTProtoHooks);
        NSLog(@"[RegTel] Successfully hooked MTProto");
    } else {
        NSLog(@"[RegTel] Warning: MTProto class not found");
    }
    
    // 2. Initialize ASTextNodeHooks if ASTextNode class is resolved
    Class textNodeClass = objc_getClass("ASTextNode");
    if (textNodeClass) {
        %init(ASTextNodeHooks);
        NSLog(@"[RegTel] Successfully hooked ASTextNode");
    } else {
        NSLog(@"[RegTel] Warning: ASTextNode class not found");
    }
    
    // 3. Initialize TelegramUIHooks if settings/chat controllers are resolved
    Class itemListClass = objc_getClass("TelegramUI.ItemListController");
    if (!itemListClass) {
        itemListClass = objc_getClass("_TtC10TelegramUI18ItemListController");
    }
    
    Class chatClass = objc_getClass("TelegramUI.ChatController");
    if (!chatClass) {
        chatClass = objc_getClass("_TtC10TelegramUI14ChatController");
    }
    
    if (itemListClass && chatClass) {
        %init(TelegramUIHooks, TelegramUI_ItemListController = itemListClass, TelegramUI_ChatController = chatClass);
        NSLog(@"[RegTel] Successfully hooked TelegramUI controllers");
    } else {
        NSLog(@"[RegTel] Warning: ItemListController or ChatController not found");
    }
    
    // 4. Initialize standard UIKit hooks (UITabBarController, UIScreen)
    %init(_ungrouped);
}
