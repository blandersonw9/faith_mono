import Foundation
import SwiftUI
import Combine

// MARK: - Bible Navigator
class BibleNavigator: ObservableObject {
    struct Selection: Equatable {
        let book: Int
        let chapter: Int
        let verse: Int?
    }

    @Published var pendingSelection: Selection? = nil

    func open(book: Int, chapter: Int, verse: Int? = nil) {
        pendingSelection = Selection(book: book, chapter: chapter, verse: verse)
    }
}


