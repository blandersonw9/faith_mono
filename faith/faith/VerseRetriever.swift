//
//  VerseRetriever.swift
//  faith
//
//  Helper to retrieve Bible verses by reference string
//

import Foundation
import SQLite3

class VerseRetriever {
    
    /// Fetch verses for a reference like "Psalm 23:1-4" or "John 14:27"
    static func fetchVerses(reference: String, translation: String = "NIV") -> [BibleVerse] {
        // Parse the reference
        guard let parsed = parseReference(reference) else {
            print("❌ Could not parse reference: \(reference)")
            return []
        }
        
        // Get translation
        let trans = BibleTranslation.getTranslation(byId: translation.lowercased()) ?? BibleTranslation.translations.first(where: { $0.abbreviation == "NIV" })!
        
        // Open database
        guard let dbPath = Bundle.main.path(forResource: trans.filename, ofType: trans.fileExtension) else {
            print("❌ Database not found: \(trans.filename).\(trans.fileExtension)")
            return []
        }
        
        var db: OpaquePointer?
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            print("❌ Could not open database")
            return []
        }
        
        defer {
            sqlite3_close(db)
        }
        
        // Build query
        var query: String
        if let endVerse = parsed.endVerse {
            // Range query: Psalm 23:1-4
            query = "SELECT id, \(trans.bookColumnName), chapter, verse, text FROM \(trans.tableName) WHERE \(trans.bookColumnName) = ? AND chapter = ? AND verse >= ? AND verse <= ? ORDER BY verse"
        } else if let verse = parsed.verse {
            // Single verse: John 14:27
            query = "SELECT id, \(trans.bookColumnName), chapter, verse, text FROM \(trans.tableName) WHERE \(trans.bookColumnName) = ? AND chapter = ? AND verse = ? ORDER BY verse"
        } else {
            // Whole chapter: Psalm 23
            query = "SELECT id, \(trans.bookColumnName), chapter, verse, text FROM \(trans.tableName) WHERE \(trans.bookColumnName) = ? AND chapter = ? ORDER BY verse"
        }
        
        var statement: OpaquePointer?
        var verses: [BibleVerse] = []
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(parsed.book))
            sqlite3_bind_int(statement, 2, Int32(parsed.chapter))
            
            if let verse = parsed.verse {
                sqlite3_bind_int(statement, 3, Int32(verse))
                if let endVerse = parsed.endVerse {
                    sqlite3_bind_int(statement, 4, Int32(endVerse))
                }
            }
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let bookNum = Int(sqlite3_column_int(statement, 1))
                let chapterNum = Int(sqlite3_column_int(statement, 2))
                let verseNum = Int(sqlite3_column_int(statement, 3))
                let text = String(cString: sqlite3_column_text(statement, 4))
                
                verses.append(BibleVerse(
                    id: id,
                    book: bookNum,
                    chapter: chapterNum,
                    verse: verseNum,
                    text: text
                ))
            }
        }
        
        sqlite3_finalize(statement)
        return verses
    }
    
    /// Parse a reference string like "Psalm 23:1-4" into components
    private static func parseReference(_ ref: String) -> (book: Int, chapter: Int, verse: Int?, endVerse: Int?)? {
        let matches = BibleReferenceUtils.findMatches(in: ref)
        guard let match = matches.first else { return nil }
        
        let selection = match.selection
        
        // Check for range in the original string
        let pattern = #"(\d+):(\d+)[\-–](\d+)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let rangeMatch = regex.firstMatch(in: ref, range: NSRange(ref.startIndex..., in: ref)) {
            let verse = Int((ref as NSString).substring(with: rangeMatch.range(at: 2))) ?? 1
            let endVerse = Int((ref as NSString).substring(with: rangeMatch.range(at: 3))) ?? verse
            return (selection.book, selection.chapter, verse, endVerse)
        }
        
        return (selection.book, selection.chapter, selection.verse, nil)
    }
}

