#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <objc/runtime.h>
#import "RegTelTweak-Swift.h"

// RegTel Tweak v1.0.1 - Ready for Actions Build

// SQLite hook imports for Anti-Recall
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

%hook MTProto

- (void)enqueueRequest:(MTRequest *)request {
    NSString *requestType = NSStringFromClass([request.body class]);
    
    // 1. Ghost Mode
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"regress_ghost_master"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"regress_ghost_noread"]) {
            if ([requestType containsString:@"messages_readHistory"] || 
                [requestType containsString:@"channels_readHistory"] ||
                [requestType containsString:@"readMentions"] ||
                [requestType containsString:@"readStories"]) {
                NSLog(@"[RegTel] Ghost Mode: Blocked outgoing read receipt: %@", requestType);
                return; // Drop!
            }
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"regress_ghost_notyping"]) {
            if ([requestType containsString:@"messages_setTyping"] || 
                [requestType containsString:@"channels_setTyping"]) {
                NSLog(@"[RegTel] Ghost Mode: Blocked outgoing typing status: %@", requestType);
                return; // Drop!
            }
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"regress_ghost_noonline"]) {
            if ([requestType containsString:@"account_updateStatus"]) {
                NSLog(@"[RegTel] Ghost Mode: Blocked outgoing online status update: %@", requestType);
                return; // Drop!
            }
        }
    }
    
    // 2. Ghost Stories (Anonymous stories view)
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"regress_ghost_stories"]) {
        if ([requestType containsString:@"stories_readStories"] || 
            [requestType containsString:@"readStories"]) {
            NSLog(@"[RegTel] Stories: Blocked stories read notification: %@", requestType);
            return; // Drop!
        }
    }
    
    // 3. Screenshot Unblocker (Block notification to server)
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"regress_unblock_screenshots"]) {
        if ([requestType containsString:@"sendScreenshotNotification"] || 
            [requestType containsString:@"messages_sendScreenshotNotification"]) {
            NSLog(@"[RegTel] Screenshot: Blocked screenshot notification to server: %@", requestType);
            return; // Drop!
        }
    }
    
    %orig(request);
}

%end

// MARK: - Hook: Anti-Recall (SQLite Layer & Caching)

%hookf(int, sqlite3_prepare_v2, sqlite3 *db, const char *zSql, int nByte, sqlite3_stmt **ppStmt, const char **pzTail) {
    if (zSql != NULL && [[NSUserDefaults standardUserDefaults] boolForKey:@"regress_antirecall_active"]) {
        NSString *sql = [NSString stringWithUTF8String:zSql];
        
        // Intercept delete statements on the message tables
        if ([sql containsString:@"DELETE FROM messages"] || 
            [sql containsString:@"delete_message"] || 
            [sql containsString:@"DELETE FROM message_history"] ||
            [sql containsString:@"delete_message_history"]) {
            
            NSLog(@"[RegTel] Anti-Recall: Blocked local SQLite message deletion: %s", zSql);
            
            // Extract numerical IDs for detailed message caching
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[0-9]{5,20}" options:0 error:nil];
            NSTextCheckingResult *match = [regex firstMatchInString:sql options:0 range:NSMakeRange(0, sql.length)];
            if (match) {
                NSString *matchStr = [sql substringWithRange:match.range];
                int64_t msgId = [matchStr longLongValue];
                
                // Track details in cache (default mock content since the raw message is preserved in DB anyway!)
                [[AyuMessageTracker shared] registerDetailedMessageDeletionWithMessageId:msgId 
                                                                               chatId:12345 // Fallback generic chat
                                                                           senderName:@"Собеседник" 
                                                                                 text:@"[Удаленное сообщение]" 
                                                                                 date:(int32_t)[[NSDate date] timeIntervalSince1970]];
            }
            
            // Bypass SQL execution: compiled statement set to NULL
            *ppStmt = NULL;
            return SQLITE_OK;
        }
    }
    return %orig(db, zSql, nByte, ppStmt, pzTail);
}

// MARK: - Hook: Tab Bar Navigation customizer

%hook UITabBarController

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated {
    NSMutableArray *mutableVCs = [viewControllers mutableCopy];
    NSMutableArray *toRemove = [NSMutableArray array];
    
    for (UIViewController *vc in mutableVCs) {
        NSString *className = NSStringFromClass([vc class]);
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"regress_hide_contacts_tab"]) {
            if ([className containsString:@"Contacts"] || [className containsString:@"ContactList"]) {
                [toRemove addObject:vc];
            }
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"regress_hide_stories_tab"]) {
            if ([className containsString:@"Story"] || [className containsString:@"Call"] || [className containsString:@"Stories"]) {
                [toRemove addObject:vc];
            }
        }
    }
    
    [mutableVCs removeObjectsInArray:toRemove];
    %orig([mutableVCs copy], animated);
}

%end

// MARK: - Hook: Local Premium (Disabled client-side to prevent crashes on non-existent Swift model classes)

// MARK: - Hook: Save Self-Destructing Media (Disabled client-side to prevent crashes on non-existent Swift model classes)

// MARK: - Hook: Screenshot Unblocker (System screen capture bypass)

%hook UIScreen
- (BOOL)isCaptured {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"regress_unblock_screenshots"]) {
        return NO; // Tricking iOS to believe screen is not recording
    }
    return %orig;
}
%end

// MARK: - Hook: Streamer Mode & Custom Profile Badges (ASTextNode)

%hook ASTextNode

- (void)setAttributedText:(NSAttributedString *)attributedText {
    if (attributedText != nil) {
        NSString *string = [attributedText string];
        NSMutableAttributedString *mutableCopy = [attributedText mutableCopy];
        BOOL modified = NO;
        
        // 1. Streamer Mode Masking
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"regress_streamer_mode"]) {
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
        NSString *selectedBadge = [[NSUserDefaults standardUserDefaults] stringForKey:@"regress_profile_badge"];
        if (selectedBadge != nil && ![selectedBadge isEqualToString:@"Без значка"]) {
            NSString *badgeChar = @"";
            if ([selectedBadge containsString:@"👑"]) badgeChar = @" 👑";
            else if ([selectedBadge containsString:@"🛡️"]) badgeChar = @" 🛡️";
            else if ([selectedBadge containsString:@"👻"]) badgeChar = @" 👻";
            else if ([selectedBadge containsString:@"⚡"]) badgeChar = @" ⚡";
            else if ([selectedBadge containsString:@"⭐"]) badgeChar = @" ⭐";
            
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

// MARK: - Hook: Custom Font Customizer (UIFont Swizzling)

%hook UIFont

+ (UIFont *)fontWithName:(NSString *)fontName size:(CGFloat)fontSize {
    NSString *customFont = [[NSUserDefaults standardUserDefaults] stringForKey:@"regress_active_font"];
    if (customFont != nil && ![customFont isEqualToString:@"Системный"]) {
        UIFont *font = [UIFont fontWithName:customFont size:fontSize];
        if (font != nil) {
            return font;
        }
    }
    return %orig(fontName, fontSize);
}

+ (UIFont *)systemFontOfSize:(CGFloat)fontSize {
    NSString *customFont = [[NSUserDefaults standardUserDefaults] stringForKey:@"regress_active_font"];
    if (customFont != nil && ![customFont isEqualToString:@"Системный"]) {
        UIFont *font = [UIFont fontWithName:customFont size:fontSize];
        if (font != nil) {
            return font;
        }
    }
    return %orig(fontSize);
}

+ (UIFont *)boldSystemFontOfSize:(CGFloat)fontSize {
    NSString *customFont = [[NSUserDefaults standardUserDefaults] stringForKey:@"regress_active_font"];
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

// MARK: - Hook Initialization & Dynamic Class Resolver

%ctor {
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
    } else {
        NSLog(@"[RegTel] Warning: TelegramUI.ItemListController or TelegramUI.ChatController not found. Settings panel hooks skipped.");
    }
    
    %init(_ungrouped);
}
