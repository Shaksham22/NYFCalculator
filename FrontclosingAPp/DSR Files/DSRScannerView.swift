import SwiftUI
import Vision
import UIKit

// MARK: – Helpers -------------------------------------------------------------

/// Individual OCR word with its bounding‐box expressed in *pixel* coordinates
private struct WordBox {
    let text: String
    let rect: CGRect   // (0,0) top-left in pixel space
}

/// Convert a Vision-space CGRect (origin bottom-left, normalised 0–1)
/// to pixel space where origin is **top-left**.
private func pixelRect(_ bb: CGRect, cgSize: CGSize) -> CGRect {
    let w = cgSize.width, h = cgSize.height
    return CGRect(x: bb.minX * w,
                  y: (1 - bb.maxY) * h,
                  width: bb.width  * w,
                  height: bb.height * h)
}

// MARK: – Reading-order utilities --------------------------------------------

private extension Array where Element == WordBox {

    /// Globally sorts word boxes:   *same line → left→right*   else -> higher first
    func sortedReadingOrder() -> [WordBox] {
        guard !isEmpty else { return [] }
        // median line-height as a robust measure
        let heights = self.map { $0.rect.height }.sorted()
        let median  = heights[count / 2]
        let thresh  = median * 0.5          // tweak 0.3–0.6 if needed

        return self.sorted { a, b in
            if abs(a.rect.midY - b.rect.midY) < thresh {
                return a.rect.minX < b.rect.minX        // same line
            } else {
                return a.rect.midY < b.rect.midY        // higher first
            }
        }
    }

    /// Groups already-sorted boxes into “lines” by mid-Y proximity
    func groupedIntoLines() -> [[WordBox]] {
        guard !isEmpty else { return [] }
        // assumption: self is in reading order
        var out: [[WordBox]] = [[self[0]]]
        let median = self.map { $0.rect.height }.sorted()[count / 2]
        let thresh = median * 0.5

        for w in dropFirst() {
            if let last = out.last, abs(last[0].rect.midY - w.rect.midY) < thresh {
                out[out.count - 1].append(w)
            } else {
                out.append([w])
            }
        }
        return out
    }
}

// MARK: – UI Model ------------------------------------------------------------

struct ParsedSection: Identifiable {
    let id = UUID()
    let name: String
    let entries: [(label: String, value: Double)]
}

// MARK: – Main View -----------------------------------------------------------

struct DSRScannerView: View {
    @State private var showImagePicker = false
    @State private var pickedImage: UIImage?
    @State private var isProcessing   = false

    // Data
    @State private var rawText: String = ""
    @State private var parsedSections: [ParsedSection] = []
    @State private var dsrMetrics: DSRMetrics?

    // UI
    @State private var showRaw = false
    @State private var showPOS = false
    @State private var showDSR = false
    @State private var showErrorAlert = false

    // Timeout
    @State private var timeoutTask: DispatchWorkItem?
    private let ocrTimeout: TimeInterval = 15

    private var canShowDSR: Bool {
        guard let diff = dsrMetrics?.cashDifference else { return false }
        return abs(diff) < 1
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                if let img = pickedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 3)
                }

                if isProcessing {
                    ProgressView("Reading…")
                }

                Button("Select DSR") { showImagePicker = true }
                    .buttonStyle(.borderedProminent)

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
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $pickedImage)
        }
        .onChange(of: pickedImage) { img in
            guard let img else { return }
            isProcessing = true
            parsedSections = []
            recognizeText(in: img)

            timeoutTask?.cancel()
            let task = DispatchWorkItem {
                isProcessing = false
                showErrorAlert = true
                dsrMetrics = nil
                parsedSections = []
            }
            timeoutTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + ocrTimeout, execute: task)
        }
        .sheet(isPresented: $showRaw) { ScrollView { Text(rawText).padding() } }
        .sheet(isPresented: $showPOS) { ParsedListView(sections: parsedSections) }
        .sheet(isPresented: $showDSR) {
            if let m = dsrMetrics { DSRReportView(m: m) }
        }
        .alert("Unable to generate DSR", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

// MARK: – OCR + Parsing -------------------------------------------------------

private extension DSRScannerView {

    func recognizeText(in image: UIImage) {
        guard let cg = image.cgImage else { return }

        let req = VNRecognizeTextRequest { [self] request, error in
            timeoutTask?.cancel()

            if let err = error {
                print("Vision error:", err.localizedDescription)
                DispatchQueue.main.async { isProcessing = false; showErrorAlert = true }
                return
            }

            let observations = (request.results as? [VNRecognizedTextObservation]) ?? []

            // 1. Build WordBox list in pixel space
            let words: [WordBox] = observations.compactMap { obs in
                guard let best = obs.topCandidates(1).first else { return nil }
                let px = pixelRect(obs.boundingBox, cgSize: CGSize(width: cg.width, height: cg.height))
                return WordBox(text: best.string, rect: px)
            }

            // 2. Resort globally & group into lines
            let rawLines = words
                .sortedReadingOrder()
                .groupedIntoLines()
                .map { $0.map(\.text).joined(separator: " ") }

//            print("—— OCR lines ————————————————————————————————")
//            rawLines.forEach { print($0) }
//            print("———————————————————————————————————————————————")

            // 3. Join + parse on main thread
            DispatchQueue.main.async {
                self.rawText = rawLines.joined(separator: "\n")

                let result  = POSSalesByOrder.parse(raw: rawText)
                let dict    = result.values
                let order   = result.displayOrder

                let precedence = ["eat in", "take out", "delivery", "end"]
                self.parsedSections = dict.map { key, inner in
                    let rows = order[key, default: []].compactMap { lbl in
                        inner[lbl].map { (lbl, $0) }
                    }
                    return ParsedSection(name: key.capitalized, entries: rows)
                }
                .sorted {
                    let ia = precedence.firstIndex(of: $0.name.lowercased()) ?? .max
                    let ib = precedence.firstIndex(of: $1.name.lowercased()) ?? .max
                    return ia < ib
                }

                self.dsrMetrics  = DSRMetrics.from(parsed: dict)
                self.isProcessing = false
                if !canShowDSR { self.showErrorAlert = true }
            }
        }

        // – Vision configuration –
        req.recognitionLevel        = .accurate
        req.recognitionLanguages    = ["en-US"]
        req.usesLanguageCorrection  = true
        req.minimumTextHeight       = 0.02
        req.revision = VNRecognizeTextRequest.currentRevision   
        DispatchQueue.global(qos: .userInitiated).async {
            try? VNImageRequestHandler(cgImage: cg, orientation: .up).perform([req])
        }
        
    }
}
