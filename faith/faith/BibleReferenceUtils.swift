import Foundation
import SwiftUI

// MARK: - Bible Reference Utilities
struct BibleReferenceMatch {
    let range: Range<String.Index>
    let display: String
    let selection: BibleNavigator.Selection
}

enum BibleReferenceUtils {
    static let nameToId: [String: Int] = {
        var m: [String: Int] = [:]
        for (id, name) in BibleManager.bookNames {
            m[normalize(name)] = id
        }
        // Common aliases
        func add(_ alias: String, _ id: Int) { m[normalize(alias)] = id }
        add("ps", 19); add("psalm", 19); add("psalms", 19)
        add("song of songs", 22); add("canticles", 22)
        add("song", 22); add("song of solomon", 22)
        add("jn", 43); add("jhn", 43); add("john", 43)
        add("lk", 42); add("luke", 42)
        add("mk", 41); add("mrk", 41); add("mark", 41)
        add("mt", 40); add("matt", 40); add("matthew", 40)
        add("rom", 45); add("romans", 45)
        add("rev", 66); add("revelation", 66); add("apocalypse", 66)
        add("1 cor", 46); add("1 co", 46); add("1 corinthians", 46)
        add("2 cor", 47); add("2 co", 47); add("2 corinthians", 47)
        add("1 sam", 9); add("1 samuel", 9)
        add("2 sam", 10); add("2 samuel", 10)
        add("1 kings", 11); add("2 kings", 12)
        add("1 kgs", 11); add("2 kgs", 12)
        add("1 chr", 13); add("2 chr", 14)
        add("1 chronicles", 13); add("2 chronicles", 14)
        add("1 thess", 52); add("2 thess", 53)
        add("1 tim", 54); add("2 tim", 55)
        add("1 pet", 60); add("2 pet", 61)
        add("1 pt", 60); add("2 pt", 61)
        add("1 jn", 62); add("2 jn", 63); add("3 jn", 64)
        add("1 john", 62); add("2 john", 63); add("3 john", 64)
        add("philem", 57); add("philemon", 57)
        add("heb", 58); add("hebrews", 58)
        add("jas", 59); add("james", 59)
        add("eph", 49); add("ephesians", 49)
        add("gal", 48); add("galatians", 48)
        add("phil", 50); add("philippians", 50)
        add("col", 51); add("colossians", 51)
        add("gen", 1); add("genesis", 1)
        add("ex", 2); add("exod", 2); add("exodus", 2)
        add("lev", 3); add("leviticus", 3)
        add("num", 4); add("numbers", 4)
        add("deut", 5); add("deuteronomy", 5)
        add("josh", 6); add("joshua", 6)
        add("judg", 7); add("judges", 7)
        add("esth", 17); add("esther", 17)
        add("eccl", 21); add("ecclesiastes", 21)
        add("isa", 23); add("isaiah", 23)
        add("jer", 24); add("jeremiah", 24)
        add("lam", 25); add("lamentations", 25)
        add("ezek", 26); add("ezekiel", 26)
        add("dan", 27); add("daniel", 27)
        add("hos", 28); add("hosea", 28)
        add("mic", 33); add("micah", 33)
        add("nah", 34); add("nahum", 34)
        add("hab", 35); add("habakkuk", 35)
        add("zeph", 36); add("zephaniah", 36)
        add("hag", 37); add("haggai", 37)
        add("zech", 38); add("zechariah", 38)
        add("mal", 39); add("malachi", 39)
        return m
    }()

    static func normalize(_ s: String) -> String {
        let lowered = s.lowercased()
        let stripped = lowered.replacingOccurrences(of: "[.]+", with: "", options: .regularExpression)
        let collapsed = stripped.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func findMatches(in text: String) -> [BibleReferenceMatch] {
        var results: [BibleReferenceMatch] = []
        // Support verse ranges with hyphen, en dash, or em dash
        let pattern = #"\b([1-3]?\s?[A-Za-z\.]+(?:\s+[A-Za-z\.]+)*)\s+(\d+)(?::(\d+)(?:[-–—](\d+))?)?\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let ns = text as NSString
        let fullRange = NSRange(location: 0, length: ns.length)
        regex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            guard let match = match else { return }
            let bookRange = match.range(at: 1)
            let chapRange = match.range(at: 2)
            let verseRange = match.range(at: 3)
            let bookStr = ns.substring(with: bookRange)
            let chapStr = ns.substring(with: chapRange)
            let verseStr = verseRange.location != NSNotFound ? ns.substring(with: verseRange) : nil
            let key = normalize(bookStr)
            guard let bookId = resolveBookId(from: key) else { return }
            let chapter = Int(chapStr) ?? 1
            let verse = verseStr != nil ? Int(verseStr!) : nil
            let r = Range(match.range, in: text)!
            let display = String(text[r])
            let sel = BibleNavigator.Selection(book: bookId, chapter: chapter, verse: verse)
            results.append(BibleReferenceMatch(range: r, display: display, selection: sel))
        }
        return results
    }

    static func resolveBookId(from key: String) -> Int? {
        // Try direct key
        if let id = nameToId[key] { return id }
        // Try to normalize numbered forms like "1john" -> "1 john"
        if let m = key.range(of: #"^[1-3](?=[a-z])"#, options: .regularExpression) {
            let pref = key[m]
            let rest = key[m.upperBound...]
            let spaced = normalize(String(pref) + " " + rest)
            if let id = nameToId[spaced] { return id }
        }
        return nil
    }

    static func linkURL(for selection: BibleNavigator.Selection) -> URL? {
        var comps = URLComponents()
        comps.scheme = "faithbible"
        comps.host = "open"
        comps.queryItems = [
            URLQueryItem(name: "book", value: String(selection.book)),
            URLQueryItem(name: "chapter", value: String(selection.chapter))
        ]
        if let v = selection.verse { comps.queryItems?.append(URLQueryItem(name: "verse", value: String(v))) }
        return comps.url
    }
}


