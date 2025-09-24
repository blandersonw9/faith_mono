//
//  LoginView.swift
//  faith
//
//  Created by Blake Anderson on 9/24/25.
//

import SwiftUI
import AVFoundation

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: StyleGuide.spacing.lg) {
                // Video Player - Square aspect ratio
                VideoPlayerView()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .clipped()
                
                // App Title
                VStack(spacing: StyleGuide.spacing.md) {
                    Text("Faith")
                        .font(StyleGuide.merriweather(size: 32, weight: .bold))
                        .foregroundColor(StyleGuide.mainBrown)
                    
                    Text("100% free Christian prayer and ai bible app")
                        .font(StyleGuide.merriweather(size: 16))
                        .foregroundColor(StyleGuide.mainBrown.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, StyleGuide.spacing.lg)
                }
                .padding(.top, StyleGuide.spacing.lg)
                
                // Sign-In Buttons
                VStack(spacing: StyleGuide.spacing.md) {
                    // Google Sign-In Button
                    Button(action: {
                        Task {
                            await authManager.signInWithGoogle()
                        }
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .font(.title2)
                            Text("Continue with Google")
                        }
                    }
                    .secondaryButtonStyle()
                    .disabled(authManager.isLoading)
                    
                    // Apple Sign-In Button (placeholder)
                    Button(action: {
                        Task {
                            await authManager.signInWithApple()
                        }
                    }) {
                        HStack {
                            Image(systemName: "applelogo")
                                .font(.title2)
                            Text("Continue with Apple")
                        }
                    }
                    .primaryButtonStyle()
                    .disabled(true) // Disabled until Apple Sign-In is configured
                    .opacity(0.6)
                }
                .padding(.horizontal, StyleGuide.spacing.lg)
            }
            .background(Color.white)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Video Player View
struct VideoPlayerView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.clear // Temporary background to see the view
        
        // Try to find the video file
        guard let videoURL = Bundle.main.url(forResource: "Preview", withExtension: "mov") else {
            print("❌ Video file not found: Preview.mov")
            
            // Create a placeholder view with text
            let label = UILabel()
            label.text = "Video not found"
            label.textAlignment = .center
            label.textColor = .white
            label.backgroundColor = .red
            label.frame = view.bounds
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(label)
            
            return view
        }
        
        print("✅ Found video file: \(videoURL)")
        
        // Create video player
        let player = AVPlayer(url: videoURL)
        let playerLayer = AVPlayerLayer(player: player)
        
        // Configure player layer
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = view.bounds
        
        // Add player layer to view
        view.layer.addSublayer(playerLayer)
        
        // Auto-play and loop
        player.actionAtItemEnd = .none
        player.play()
        
        // Loop the video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        
        // Mute the video
        player.isMuted = true
        
        // Add error handling
        player.addObserver(context.coordinator, forKeyPath: "status", options: [.new], context: nil)
        
        // Force layout update
        DispatchQueue.main.async {
            playerLayer.frame = view.bounds
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update frame when view size changes
        if let playerLayer = uiView.layer.sublayers?.first as? AVPlayerLayer {
            playerLayer.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == "status" {
                if let player = object as? AVPlayer {
                    switch player.status {
                    case .readyToPlay:
                        print("✅ Video player ready to play")
                        player.play()
                    case .failed:
                        print("❌ Video player failed: \(player.error?.localizedDescription ?? "Unknown error")")
                    case .unknown:
                        print("⏳ Video player status unknown")
                    @unknown default:
                        print("❓ Video player status unknown")
                    }
                }
            } else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            }
        }
    }
}


#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
