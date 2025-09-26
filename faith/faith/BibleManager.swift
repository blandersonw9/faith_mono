//
//  BibleManager.swift
//  faith
//
//  Created by Blake Anderson on 9/24/25.
//

import Foundation
import SQLite3
import Combine

struct BibleVerse {
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

class BibleManager: ObservableObject {
    @Published var verses: [BibleVerse] = []
    @Published var isLoading = false
    @Published var currentBook = 1
    @Published var currentChapter = 1
    @Published var errorMessage: String?
    
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
        guard let dbPath = Bundle.main.path(forResource: "kjv", ofType: "sqlite") else {
            errorMessage = "Could not find Bible database"
            return
        }
        
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            errorMessage = "Could not open Bible database"
            return
        }
    }
    
    private func closeDatabase() {
        if sqlite3_close(db) != SQLITE_OK {
            print("Error closing database")
        }
    }
    
    func loadVerses(book: Int, chapter: Int) {
        print("BibleManager.loadVerses called with: Book \(book), Chapter \(chapter)")
        isLoading = true
        errorMessage = nil
        
        let query = "SELECT id, book, chapter, verse, text FROM verses WHERE book = ? AND chapter = ? ORDER BY verse"
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
            DispatchQueue.main.async {
                self.errorMessage = "Error preparing query"
                self.isLoading = false
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    func getAvailableChapters(for book: Int) -> [Int] {
        let query = "SELECT DISTINCT chapter FROM verses WHERE book = ? ORDER BY chapter"
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
        let query = "SELECT DISTINCT book FROM verses ORDER BY book"
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
