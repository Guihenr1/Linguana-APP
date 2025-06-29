// AudioManager.swift
import Foundation
import AVFoundation

class AudioManager: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    
    @Published var isRecording = false
    @Published var transcription = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        setupAudioRecorder()
    }
    
    private func setupAudioRecorder() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            // Create URL for the audio file
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            recordingURL = documentsPath.appendingPathComponent("recording.m4a")
            
            guard let recordingURL = recordingURL else { return }
            
            // Audio recording settings
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.prepareToRecord()
        } catch {
            errorMessage = "Audio session setup error: \(error.localizedDescription)"
        }
    }
    
    func toggleRecording() {
        if !isRecording {
            startRecording()
        } else {
            stopRecording()
        }
    }
    
    private func startRecording() {
        guard let audioRecorder = audioRecorder else { return }
        
        audioRecorder.record()
        isRecording = true
        transcription = ""
        errorMessage = nil
    }
    
    private func stopRecording() {
        guard let audioRecorder = audioRecorder else { return }
        
        audioRecorder.stop()
        isRecording = false
        
        if let recordingURL = recordingURL {
            uploadAudioFile(from: recordingURL)
        }
    }
    
    private func uploadAudioFile(from url: URL) {
        let boundary = UUID().uuidString
        
        var request = URLRequest(url: URL(string: "https://linguana-api.azurewebsites.net/api/speech/transcribe")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let audioData: Data
        do {
            audioData = try Data(contentsOf: url)
        } catch {
            errorMessage = "Error reading audio file: \(error.localizedDescription)"
            return
        }
        
        var body = Data()
        
        // Add audio file data
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"audioFile\"; filename=\"recording.m4a\"\r\n")
        body.append("Content-Type: audio/m4a\r\n\r\n")
        body.append(audioData)
        body.append("\r\n")
        
        body.append("--\(boundary)--\r\n")
        
        request.httpBody = body
        
        isLoading = true
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                if let data = data {
                    do {
                        let json = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
                        self?.transcription = json.transcription
                    } catch {
                        self?.errorMessage = "Error decoding response: \(error.localizedDescription)"
                    }
                }
            }
        }.resume()
    }
}
