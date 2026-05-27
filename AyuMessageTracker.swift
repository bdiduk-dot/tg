import Foundation

@objc public class AyuMessageTracker: NSObject {
    @objc public static let shared = AyuMessageTracker()
    
    private let queue = DispatchQueue(label: "com.regress.regtel.MessageTracker", qos: .utility)
    
    // Store complete deleted message structures: [chatId: [[String: Any]]]
    private var deletedMessagesByChat: [Int64: [[String: Any]]] = [:]
    private var deletedMessageIds: Set<Int64> = []
    private var editedHistory: [Int64: [[String: Any]]] = [:]
    
    private var cacheDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("RegressCache")
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        return dir
    }
    
    private var deletedFileUrl: URL {
        return cacheDirectory.appendingPathComponent("deleted_messages_detailed.json")
    }
    
    private var editedFileUrl: URL {
        return cacheDirectory.appendingPathComponent("edited_history.json")
    }
    
    private override init() {
        super.init()
        loadCache()
    }
    
    // MARK: - Cache Operations
    
    private func loadCache() {
        queue.async {
            // Load detailed deleted messages
            if let data = try? Data(contentsOf: self.deletedFileUrl),
               let history = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: [[String: Any]]] {
                var converted: [Int64: [[String: Any]]] = [:]
                var ids = Set<Int64>()
                for (key, val) in history {
                    if let chatId = Int64(key) {
                        converted[chatId] = val
                        for item in val {
                            if let msgId = item["messageId"] as? Int64 {
                                ids.insert(msgId)
                            }
                        }
                    }
                }
                self.deletedMessagesByChat = converted
                self.deletedMessageIds = ids
            }
            
            // Load edited history
            if let data = try? Data(contentsOf: self.editedFileUrl),
               let history = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: [[String: Any]]] {
                var converted: [Int64: [[String: Any]]] = [:]
                for (key, val) in history {
                    if let id = Int64(key) {
                        converted[id] = val
                    }
                }
                self.editedHistory = converted
            }
        }
    }
    
    private func saveDeletedCache() {
        queue.async {
            var converted: [String: [[String: Any]]] = [:]
            for (key, val) in self.deletedMessagesByChat {
                converted[String(key)] = val
            }
            if let data = try? JSONSerialization.data(withJSONObject: converted, options: []) {
                try? data.write(to: self.deletedFileUrl)
            }
        }
    }
    
    private func saveEditedCache() {
        queue.async {
            var converted: [String: [[String: Any]]] = [:]
            for (key, val) in self.editedHistory {
                converted[String(key)] = val
            }
            if let data = try? JSONSerialization.data(withJSONObject: converted, options: []) {
                try? data.write(to: self.editedFileUrl)
            }
        }
    }
    
    // MARK: - Public API
    
    @objc public func registerDetailedMessageDeletion(messageId: Int64, chatId: Int64, senderName: String, text: String, date: Int32) {
        queue.async {
            self.deletedMessageIds.insert(messageId)
            
            let entry: [String: Any] = [
                "messageId": messageId,
                "chatId": chatId,
                "senderName": senderName.isEmpty ? "Пользователь" : senderName,
                "text": text.isEmpty ? "[Медиа или пустое сообщение]" : text,
                "date": date
            ]
            
            var list = self.deletedMessagesByChat[chatId] ?? []
            // Avoid duplicate deletions
            if !list.contains(where: { ($0["messageId"] as? Int64) == messageId }) {
                list.append(entry)
                self.deletedMessagesByChat[chatId] = list
                self.saveDeletedCache()
            }
        }
    }
    
    @objc public func isMessageDeletedLocally(messageId: Int64) -> Bool {
        var isDeleted = false
        queue.sync {
            isDeleted = self.deletedMessageIds.contains(messageId)
        }
        return isDeleted
    }
    
    @objc public func getDeletedMessages(forChatId chatId: Int64) -> [[String: Any]] {
        var history: [[String: Any]] = []
        queue.sync {
            history = self.deletedMessagesByChat[chatId] ?? []
        }
        return history
    }
    
    @objc public func hasDeletedMessages(forChatId chatId: Int64) -> Bool {
        var hasMessages = false
        queue.sync {
            hasMessages = !(self.deletedMessagesByChat[chatId] ?? []).isEmpty
        }
        return hasMessages
    }
    
    @objc public func registerMessageEdit(messageId: Int64, previousText: String, date: Int32) {
        queue.async {
            let entry: [String: Any] = [
                "text": previousText,
                "date": date
            ]
            var list = self.editedHistory[messageId] ?? []
            if let last = list.last, (last["text"] as? String) == previousText {
                return
            }
            list.append(entry)
            self.editedHistory[messageId] = list
            self.saveEditedCache()
        }
    }
    
    @objc public func getEditHistory(messageId: Int64) -> [[String: Any]] {
        var history: [[String: Any]] = []
        queue.sync {
            history = self.editedHistory[messageId] ?? []
        }
        return history
    }
    
    @objc public func clearAllCache() {
        queue.async {
            self.deletedMessageIds.removeAll()
            self.deletedMessagesByChat.removeAll()
            self.editedHistory.removeAll()
            try? FileManager.default.removeItem(at: self.deletedFileUrl)
            try? FileManager.default.removeItem(at: self.editedFileUrl)
        }
    }
}
