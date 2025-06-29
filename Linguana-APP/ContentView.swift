// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Button(action: {
                audioManager.toggleRecording()
            }) {
                Text(audioManager.isRecording ? "Stop Recording" : "Click to Speech")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(audioManager.isRecording ? Color.red : Color.blue)
                    .cornerRadius(10)
            }
            .disabled(audioManager.isLoading)
            
            if audioManager.isLoading {
                ProgressView("Transcribing...")
            }
            
            if let errorMessage = audioManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            if !audioManager.transcription.isEmpty {
                Text(audioManager.transcription)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
