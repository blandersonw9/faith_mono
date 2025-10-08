//
//  BibleManager.swift
//  faith
//
//  Created by Blake Anderson on 9/24/25.
//

import Foundation
import SQLite3
import Combine

struct BibleVerse: Equatable {
    let id: Int
    let book: Int
    let chapter: Int
    let verse: Int
    let text: String
    
    var bookName: String {
        return BibleManager.bookNames[book] ?? "Unknown Book"
    }
    
    var formattedReference: String {
        return "\(bookName) \(chapter):\(verse)"
    }
}

struct BibleTranslation {
    let id: String
    let name: String
    let abbreviation: String
    let filename: String
    let fileExtension: String
    let tableName: String
    let bookColumnName: String
    
    static let translations: [BibleTranslation] = [
        BibleTranslation(
            id: "kjv",
            name: "King James Version",
            abbreviation: "KJV",
            filename: "kjv",
            fileExtension: "sqlite",
            tableName: "verses",
            bookColumnName: "book"
        ),
        BibleTranslation(
            id: "niv",
            name: "New International Version",
            abbreviation: "NIV",
            filename: "niv",
            fileExtension: "db",
            tableName: "niv",
            bookColumnName: "book_id"
        ),
        BibleTranslation(
            id: "esv",
            name: "English Standard Version",
            abbreviation: "ESV",
            filename: "esv",
            fileExtension: "db",
            tableName: "esv",
            bookColumnName: "book_id"
        ),
        BibleTranslation(
            id: "csb",
            name: "Christian Standard Bible",
            abbreviation: "CSB",
            filename: "csb",
            fileExtension: "db",
            tableName: "csb",
            bookColumnName: "book_id"
        ),
        BibleTranslation(
            id: "nlt",
            name: "New Living Translation",
            abbreviation: "NLT",
            filename: "nlt",
            fileExtension: "db",
            tableName: "nlt",
            bookColumnName: "book_id"
        )
    ]
    
    static func getTranslation(byId id: String) -> BibleTranslation? {
        return translations.first { $0.id == id }
    }
    
    /// Check if this translation's database file exists in the bundle
    var isAvailable: Bool {
        let path = Bundle.main.path(forResource: filename, ofType: fileExtension)
        let available = path != nil
        #if DEBUG
        print("📚 Translation \(abbreviation): \(available ? "✅ Available" : "❌ Not found") - looking for: \(filename).\(fileExtension)")
        if let p = path {
            print("   Found at: \(p)")
        }
        #endif
        return available
    }
    
    /// Get only translations that have their database files available
    static var availableTranslations: [BibleTranslation] {
        return translations.filter { $0.isAvailable }
    }
}

class BibleManager: ObservableObject {
    @Published var verses: [BibleVerse] = []
    @Published var isLoading = false
    @Published var currentBook = 1
    @Published var currentChapter = 1
    @Published var errorMessage: String?
    @Published var currentTranslation: BibleTranslation = {
        let savedId = UserDefaults.standard.string(forKey: "bibleTranslation") ?? "kjv"
        return BibleTranslation.getTranslation(byId: savedId) ?? BibleTranslation.translations[0]
    }()
    
    private var db: OpaquePointer?
    
    static let bookNames: [Int: String] = [
        1: "Genesis", 2: "Exodus", 3: "Leviticus", 4: "Numbers", 5: "Deuteronomy",
        6: "Joshua", 7: "Judges", 8: "Ruth", 9: "1 Samuel", 10: "2 Samuel",
        11: "1 Kings", 12: "2 Kings", 13: "1 Chronicles", 14: "2 Chronicles", 15: "Ezra",
        16: "Nehemiah", 17: "Esther", 18: "Job", 19: "Psalms", 20: "Proverbs",
        21: "Ecclesiastes", 22: "Song of Solomon", 23: "Isaiah", 24: "Jeremiah", 25: "Lamentations",
        26: "Ezekiel", 27: "Daniel", 28: "Hosea", 29: "Joel", 30: "Amos",
        31: "Obadiah", 32: "Jonah", 33: "Micah", 34: "Nahum", 35: "Habakkuk",
        36: "Zephaniah", 37: "Haggai", 38: "Zechariah", 39: "Malachi", 40: "Matthew",
        41: "Mark", 42: "Luke", 43: "John", 44: "Acts", 45: "Romans",
        46: "1 Corinthians", 47: "2 Corinthians", 48: "Galatians", 49: "Ephesians", 50: "Philippians",
        51: "Colossians", 52: "1 Thessalonians", 53: "2 Thessalonians", 54: "1 Timothy", 55: "2 Timothy",
        56: "Titus", 57: "Philemon", 58: "Hebrews", 59: "James", 60: "1 Peter",
        61: "2 Peter", 62: "1 John", 63: "2 John", 64: "3 John", 65: "Jude", 66: "Revelation"
    ]
    
    init() {
        openDatabase()
    }
    
    deinit {
        closeDatabase()
    }
    
    private func openDatabase() {
        // Close existing database if open
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
        
        guard let dbPath = Bundle.main.path(forResource: currentTranslation.filename, ofType: currentTranslation.fileExtension) else {
            errorMessage = "Could not find \(currentTranslation.abbreviation) Bible database"
            #if DEBUG
            print("❌ Failed to find database: \(currentTranslation.filename).\(currentTranslation.fileExtension)")
            #endif
            return
        }
        
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            errorMessage = "Could not open \(currentTranslation.abbreviation) Bible database"
            #if DEBUG
            print("❌ Failed to open database: \(currentTranslation.abbreviation)")
            if let errorMessage = String(validatingUTF8: sqlite3_errmsg(db)) {
                print("   SQLite error: \(errorMessage)")
            }
            #endif
            return
        }
        
        #if DEBUG
        print("Successfully opened \(currentTranslation.abbreviation) database at: \(dbPath)")
        #endif
    }
    
    func switchTranslation(_ translation: BibleTranslation) {
        #if DEBUG
        print("🔄 Switching translation to: \(translation.abbreviation)")
        #endif
        currentTranslation = translation
        UserDefaults.standard.set(translation.id, forKey: "bibleTranslation")
        openDatabase()
        // Reload current chapter with new translation
        #if DEBUG
        print("🔄 Reloading verses for: \(translation.abbreviation), book: \(currentBook), chapter: \(currentChapter)")
        #endif
        loadVerses(book: currentBook, chapter: currentChapter)
    }
    
    private func closeDatabase() {
        if sqlite3_close(db) != SQLITE_OK {
            print("Error closing database")
        }
    }
    
    func loadVerses(book: Int, chapter: Int) {
        print("BibleManager.loadVerses called with: Book \(book), Chapter \(chapter), Translation: \(currentTranslation.abbreviation)")
        isLoading = true
        errorMessage = nil
        
        // Build query based on current translation's schema
        let query = "SELECT id, \(currentTranslation.bookColumnName), chapter, verse, text FROM \(currentTranslation.tableName) WHERE \(currentTranslation.bookColumnName) = ? AND chapter = ? ORDER BY verse"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(book))
            sqlite3_bind_int(statement, 2, Int32(chapter))
            
            var verses: [BibleVerse] = []
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let bookNum = Int(sqlite3_column_int(statement, 1))
                let chapterNum = Int(sqlite3_column_int(statement, 2))
                let verseNum = Int(sqlite3_column_int(statement, 3))
                let text = String(cString: sqlite3_column_text(statement, 4))
                
                let bibleVerse = BibleVerse(
                    id: id,
                    book: bookNum,
                    chapter: chapterNum,
                    verse: verseNum,
                    text: text
                )
                verses.append(bibleVerse)
            }
            
            DispatchQueue.main.async {
                self.verses = verses
                self.currentBook = book
                self.currentChapter = chapter
                self.isLoading = false
                print("BibleManager updated: currentBook=\(self.currentBook), currentChapter=\(self.currentChapter), verses count=\(verses.count)")
            }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            DispatchQueue.main.async {
                self.errorMessage = "Error preparing query: \(errorMsg)"
                self.isLoading = false
            }
            #if DEBUG
            print("SQL Error: \(errorMsg)")
            print("Query: \(query)")
            #endif
        }
        
        sqlite3_finalize(statement)
    }
    
    func getAvailableChapters(for book: Int) -> [Int] {
        let query = "SELECT DISTINCT chapter FROM \(currentTranslation.tableName) WHERE \(currentTranslation.bookColumnName) = ? ORDER BY chapter"
        var statement: OpaquePointer?
        var chapters: [Int] = []
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(book))
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let chapter = Int(sqlite3_column_int(statement, 0))
                chapters.append(chapter)
            }
        }
        
        sqlite3_finalize(statement)
        return chapters
    }
    
    func getAvailableBooks() -> [(id: Int, name: String)] {
        let query = "SELECT DISTINCT \(currentTranslation.bookColumnName) FROM \(currentTranslation.tableName) ORDER BY \(currentTranslation.bookColumnName)"
        var statement: OpaquePointer?
        var books: [(id: Int, name: String)] = []
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let bookId = Int(sqlite3_column_int(statement, 0))
                let bookName = BibleManager.bookNames[bookId] ?? "Unknown Book"
                books.append((id: bookId, name: bookName))
            }
        }
        
        sqlite3_finalize(statement)
        return books
    }
}
