//
//  HomeView.swift
//  RecognizeSpeech
//
//  Created by thaxz on 22/08/24.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject private var speechManager = SpeechManager()
    var body: some View {
        VStack(spacing: 50){
            Text(speechManager.recognizedText ?? "Clique para começar")
                .font(.system(size: 20, weight: .semibold))
            Button {
                toggleSpeechRecognition()
            } label: {
                Image(systemName: speechManager.isProcessing ? "waveform.circle.fill" : "waveform.circle")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(speechManager.isProcessing ? .blue : .gray)
            }
        }
    }
}

private extension HomeView {
    func toggleSpeechRecognition() {
        if speechManager.isProcessing {
            speechManager.stopRecognition()
        } else {
            speechManager.startRecognition()
        }
    }
}

#Preview {
    HomeView()
}
