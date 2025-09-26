import SwiftUI
import Supabase

struct BibleView: View {
    @StateObject private var bibleManager = BibleManager()
    @State private var showingBookPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with combined book/chapter selector
            HStack {
                Spacer()
                
                Button(action: {
                    showingBookPicker = true
                }) {
                    HStack {
                        Text(bibleManager.currentBook > 0 ? 
                             "\(BibleManager.bookNames[bibleManager.currentBook] ?? "Select Book") \(bibleManager.currentChapter)" : 
                             "Select Book")
                            .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                            .foregroundColor(StyleGuide.mainBrown)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(StyleGuide.mainBrown)
                    }
                    .padding(.horizontal, StyleGuide.spacing.md)
                    .padding(.vertical, StyleGuide.spacing.sm)
                    .background(Color.white)
                    .cornerRadius(StyleGuide.cornerRadius.sm)
                    .shadow(color: StyleGuide.shadows.sm, radius: 2, x: 0, y: 1)
                }
                
                Spacer()
            }
            .padding(.horizontal, StyleGuide.spacing.lg)
            .padding(.top, StyleGuide.spacing.md)
            
            // Bible content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: StyleGuide.spacing.md) {
                    if bibleManager.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: StyleGuide.mainBrown))
                            Spacer()
                        }
                        .padding(.top, StyleGuide.spacing.xl)
                    } else if let errorMessage = bibleManager.errorMessage {
                        Text(errorMessage)
                            .font(StyleGuide.merriweather(size: 14))
                            .foregroundColor(.red)
        .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(StyleGuide.cornerRadius.sm)
                            .padding(.horizontal, StyleGuide.spacing.lg)
                    } else {
                        ForEach(bibleManager.verses, id: \.id) { verse in
                            HStack(alignment: .top, spacing: StyleGuide.spacing.sm) {
                                Text("\(verse.verse)")
                                    .font(StyleGuide.merriweather(size: 12, weight: .bold))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                                    .frame(width: 20, alignment: .trailing)
                                
                                Text(verse.text)
                                    .font(StyleGuide.merriweather(size: 16))
                                    .foregroundColor(StyleGuide.mainBrown)
                                    .lineSpacing(4)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.horizontal, StyleGuide.spacing.lg)
                        }
                    }
                }
                .padding(.top, StyleGuide.spacing.md)
            }
        }
        .background(StyleGuide.backgroundBeige.ignoresSafeArea(.all))
        .onAppear {
            if bibleManager.verses.isEmpty {
                bibleManager.loadVerses(book: 1, chapter: 1) // Load Genesis 1 by default
            }
        }
        .sheet(isPresented: $showingBookPicker) {
            BookPickerView(bibleManager: bibleManager)
        }
    }
}

// MARK: - Book Picker
struct BookPickerView: View {
    @ObservedObject var bibleManager: BibleManager
    @Environment(\.presentationMode) var presentationMode
    @State private var expandedBook: Int? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(bibleManager.getAvailableBooks(), id: \.id) { book in
                    VStack(alignment: .leading, spacing: 0) {
                        // Book name button
                        Button(action: {
                            if expandedBook == book.id {
                                expandedBook = nil
                            } else {
                                expandedBook = book.id
                            }
                        }) {
                            HStack {
                                Text(book.name)
                                    .font(StyleGuide.merriweather(size: 16, weight: .medium))
                                    .foregroundColor(StyleGuide.mainBrown)
                                
                                Spacer()
                                
                                Image(systemName: expandedBook == book.id ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(StyleGuide.mainBrown)
                            }
                            .padding(.horizontal, StyleGuide.spacing.lg)
                            .padding(.vertical, StyleGuide.spacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Chapters grid
                        if expandedBook == book.id {
                            VStack(spacing: StyleGuide.spacing.sm) {
                                ForEach(0..<(bibleManager.getAvailableChapters(for: book.id).count + 4) / 5, id: \.self) { row in
                                    HStack(spacing: 4) {
                                        ForEach(0..<5, id: \.self) { col in
                                            let chapterIndex = row * 5 + col
                                            if chapterIndex < bibleManager.getAvailableChapters(for: book.id).count {
                                                let chapter = bibleManager.getAvailableChapters(for: book.id)[chapterIndex]
                                                Button(action: {
                                                    print("Selected: Book \(book.id), Chapter \(chapter)")
                                                    bibleManager.loadVerses(book: book.id, chapter: chapter)
                                                    presentationMode.wrappedValue.dismiss()
                                                }) {
                                                    Text("\(chapter)")
                                                        .font(StyleGuide.merriweather(size: 14, weight: .medium))
                                                        .foregroundColor(StyleGuide.mainBrown)
                                                        .frame(maxWidth: .infinity)
                                                        .frame(height: 44)
                                                        .background(StyleGuide.backgroundBeige)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: StyleGuide.cornerRadius.sm)
                                                                .stroke(StyleGuide.mainBrown.opacity(0.25), lineWidth: 1)
                                                        )
                                                        .cornerRadius(StyleGuide.cornerRadius.sm)
                                                        .shadow(color: StyleGuide.shadows.sm, radius: 2, x: 0, y: 1)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            } else {
                                                Spacer()
                                                    .frame(maxWidth: .infinity, minHeight: 44)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, StyleGuide.spacing.lg)
                                }
                            }
                            .padding(.bottom, StyleGuide.spacing.md)
                        }
                    }
                    
                    // Divider between books
                    if book.id != bibleManager.getAvailableBooks().last?.id {
                        Rectangle()
                            .fill(StyleGuide.mainBrown.opacity(0.1))
                            .frame(height: 1)
                            .padding(.horizontal, StyleGuide.spacing.lg)
                    }
                }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

