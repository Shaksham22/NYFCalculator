import SwiftUI
import Vision
import UIKit

// MARK: – Model for POS sections
struct ParsedSection: Identifiable {
    let id = UUID()
    let name: String
    let entries: [(label: String, value: Double)]
}

// MARK: – Main View
struct DSRScannerView: View {
    @State private var showImagePicker = false
    @State private var pickedImage: UIImage?
    @State private var isProcessing = false

    // Data
    @State private var rawText: String = ""
    @State private var parsedSections: [ParsedSection] = []
    @State private var dsrMetrics: DSRMetrics?

    // UI State
    @State private var showRaw = false
    @State private var showPOS = false
    @State private var showDSR = false
    @State private var showErrorAlert = false
    
    @State private var timeoutTask: DispatchWorkItem?
    private let ocrTimeout: TimeInterval = 15

    private var canShowDSR: Bool {
        guard let diff = dsrMetrics?.cashDifference else { return false }
        return abs(diff) < 1
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Preview Image
                if let img = pickedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 3)
                }

                // Loading
                if isProcessing {
                    ProgressView("Reading…")
                }

                // Select Image Button
                Button("Select DSR") {
                    showImagePicker = true
                }
                .buttonStyle(.borderedProminent)

                // Action Buttons
                VStack(spacing: 8) {
                    Button("Show Raw OCR") { showRaw = true }
                        .buttonStyle(.bordered)
                        .disabled(rawText.isEmpty)

                    Button("Show POS Parse") { showPOS = true }
                        .buttonStyle(.bordered)
                        .disabled(parsedSections.isEmpty)

                    Button("Show DSR Sheet") { showDSR = true }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canShowDSR)
                }
            }
            .padding()
        }

        // Image Picker
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $pickedImage)
        }

        // Image Change Trigger
        .onChange(of: pickedImage) { img in
            guard let img else { return }
            isProcessing = true
            parsedSections = []
            recognizeText(in: img)
            timeoutTask?.cancel()
            timeoutTask = nil

            // Schedule new timeout
            let task = DispatchWorkItem {
                // Runs on main thread when the deadline fires
                isProcessing = false
                showErrorAlert = true
                dsrMetrics = nil
                parsedSections = []
            }
            timeoutTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + ocrTimeout, execute: task)

        }

        // Sheet Views
        .sheet(isPresented: $showRaw) {
            ScrollView { Text(rawText).padding() }
        }
        .sheet(isPresented: $showPOS) {
            ParsedListView(sections: parsedSections)
        }
        .sheet(isPresented: $showDSR) {
            if let m = dsrMetrics {
                DSRReportView(m: m)
            }
        }

        // Error Alert
        .alert("Unable to generate DSR", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

// MARK: – OCR + Parsing + Calculation
private extension DSRScannerView {
    func recognizeText(in image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let request = VNRecognizeTextRequest { req, err in
            // ── Cancel any pending timeout immediately ─────────────
            timeoutTask?.cancel()
            timeoutTask = nil

            // ── Handle Vision error ────────────────────────────────
            if let error = err {
                print("Vision error:", error.localizedDescription)
                DispatchQueue.main.async {
                    isProcessing = false
                    showErrorAlert = true   // show error right away
                }
                return
            }

            // ── Success: pull raw OCR text ─────────────────────────
            let raw = req.results?
                .compactMap { $0 as? VNRecognizedTextObservation }
                .flatMap { $0.topCandidates(1) }
                .map(\.string)
                .joined(separator: "\n") ?? ""

            rawText = raw

            // ── Parse POS → Sections ───────────────────────────────
            let result = POSSalesByOrder.parse(raw: raw)
            let dict   = result.values
            let order  = result.displayOrder

            let precedence = ["eat in", "take out", "delivery", "end"]
            let sections: [ParsedSection] = dict.map { key, inner in
                var pairs: [(String, Double)] = order[key, default: []]
                    .compactMap { lbl in
                        guard let v = inner[lbl] else { return nil }
                        return (lbl, v)
                    }
                let extras = inner
                    .filter { !order[key, default: []].contains($0.key) }
                    .sorted { $0.key < $1.key }
                pairs.append(contentsOf: extras.map { ($0.key, $0.value) })
                return ParsedSection(name: key, entries: pairs)
            }
            .sorted {
                let ia = precedence.firstIndex(of: $0.name) ?? .max
                let ib = precedence.firstIndex(of: $1.name) ?? .max
                return ia < ib
            }

            // ── Calculate DSR metrics ───────────────────────────────
            dsrMetrics = DSRMetrics.from(parsed: dict)

            // ── Update UI ──────────────────────────────────────────
            DispatchQueue.main.async {
                parsedSections = sections
                isProcessing   = false
                if !canShowDSR {
                    showErrorAlert = true
                }
            }
        }

        request.recognitionLevel     = .accurate
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}
