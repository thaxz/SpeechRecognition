//
//  SpeechManager.swift
//  RecognizeSpeech
//
//  Created by thaxz on 22/08/24.
//

import Foundation
import Speech

final class SpeechManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate {

    // Analyzes live audio
    private let audioEngine: AVAudioEngine = AVAudioEngine()
    private var audioSession: AVAudioSession?
    private var inputNode: AVAudioInputNode?

    // Handle Speech Recognition
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    @Published var recognizedText: String?
    @Published var isProcessing: Bool = false

    /// Starts the speech recognition process
    func startRecognition() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch authStatus {
                    case .authorized:
                        self.setupRecognition()
                    case .denied, .restricted, .notDetermined:
                        self.handleAuthorizationError()
                    @unknown default:
                        fatalError("Status de autorização desconhecido.")
                }
            }
        }
    }

    /// Stops running tasks, audio engine, removes the tap on inputNode, informs that analyzer is not processing, clears the memory.
    func stopRecognition() {
        recognitionTask?.cancel()
        audioEngine.stop()
        inputNode?.removeTap(onBus: 0)
        try? audioSession?.setActive(false)

        isProcessing = false
        cleanup()
    }

    /// Updates the availability status of the speech recognizer
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer,
                          availabilityDidChange available: Bool) {
        if available {
            print("Reconhecimento de fala disponível.")
        } else {
            print("Reconhecimento de fala indisponível.")
            recognizedText = "Reconhecimento de fala indisponível."
            stopRecognition()
        }
    }

    /// Configures the audio session and starts speech recognition setup
    private func setupRecognition() {
        configureAudioSession()
        configureSpeechRecognition()
        createRecognitionTask()
        startAudioEngine()
    }

    /// Configures the audio session
    private func configureAudioSession(){
        audioSession = AVAudioSession.sharedInstance()
        do {
            // Silences other sounds and minimize system-supplied signal processing
            try audioSession?.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession?.setActive(true, options: .notifyOthersOnDeactivation)
            inputNode = audioEngine.inputNode
        } catch {
            print("Erro ao configurar a sessão de áudio: \(error.localizedDescription)")
        }
    }

    /// Configures speech recognition with the user's locale and request settings
    private func configureSpeechRecognition(){
        // Using user's current locale
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt_BR"))
        // Customs the way we want to process the audio
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        // Results updating in real-time
        recognitionRequest?.shouldReportPartialResults = true
    }

    /// Creates and starts the speech recognition task
    private func createRecognitionTask() {
        guard let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable,
              let recognitionRequest = recognitionRequest,
              let inputNode = inputNode else {
            assertionFailure("Failed to configure speech recognition.")
            return
        }

        speechRecognizer.delegate = self
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] 
            buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] 
            result, error in
            DispatchQueue.main.async {
                self?.recognizedText = result?.bestTranscription.formattedString
                if error != nil || result?.isFinal == true {
                    self?.stopRecognition()
                }
            }
        }
    }

    /// Starts the audio engine for capturing audio input
    private func startAudioEngine() {
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isProcessing = true
        } catch {
            print("Não foi possível iniciar a engine de áudio: \(error.localizedDescription)")
            stopRecognition()
        }
    }

    /// Handles authorization errors by updating the recognized text and stop tasks
    private func handleAuthorizationError() {
        recognizedText = "Permissão para reconhecimento de fala não concedida."
        stopRecognition()
    }

    // Cleans up resources and reset configuration
    private func cleanup() {
        recognitionRequest = nil
        recognitionTask = nil
        speechRecognizer = nil
    }

}
