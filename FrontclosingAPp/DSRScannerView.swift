import SwiftUI
import Vision
import UIKit

struct DSRScannerView: View {
    @State private var showPicker = false
    @State private var selectedImage: UIImage?
    @State private var extractedText: [String] = []

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack {
                Text("Scan Receipt for DSR")
                    .font(.title2)
                    .padding(.top)

                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .cornerRadius(10)
                        .padding()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 250)
                        .overlay(Text("No Image Selected").foregroundColor(.gray))
                        .cornerRadius(10)
                        .padding()
                }

                ScrollView {
                    if !extractedText.isEmpty {
                        Text(extractedText.joined(separator: "\n"))
                            .font(.system(.body, design: .monospaced))
                            .padding()
                    }
                }

                Spacer()
            }

            // 🔽 Gallery Icon Button (bottom right corner)
            Button(action: {
                showPicker = true
            }) {
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
                    .shadow(radius: 3)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                extractText(from: image) { lines in
                    DispatchQueue.main.async {
                        self.extractedText = lines
                    }
                }
            }
        }
    }

    func extractText(from image: UIImage, completion: @escaping ([String]) -> Void) {
        guard let cgImage = image.cgImage else { return }

        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion([])
                return
            }

            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            completion(lines)
        }

        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}
