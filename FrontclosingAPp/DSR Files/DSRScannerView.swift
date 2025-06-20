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
    @State private var showCamera = false // for full-screen capture
    @State private var showCropper  = false
    @State private var showWeScanCamera    = false
    @State private var pendingGalleryImage: UIImage?
    @State private var showWeScanGallery    = false
    @State private var galleryRawImage: UIImage?
    @State private var showDSRCreatedAlert = false

    // Timeout
    @State private var timeoutTask: DispatchWorkItem?
    private let ocrTimeout: TimeInterval = 15

    private var canShowDSR: Bool {
        guard let diff = dsrMetrics?.cashDifference else { return false }
        return abs(diff) < 1
    }

    var body: some View {
        let buttonWidth: CGFloat = 130
        ScrollView {
            VStack(spacing: 20){
                
                // MARK: – Preview & Status
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
                
                // MARK: – Input Section
                GroupBox("Input") {
                    HStack(spacing: 16) {
                        Button("Select Receipt from Gallery") { showImagePicker = true }
                        Button("Take Photo of the Receipt")  { showWeScanCamera = true }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // MARK: – Review & Debug Section
                GroupBox("Action") {
                    VStack{
                        HStack(spacing: 10) {
                            
                            Button("Show DSR")  { showDSR = true }
                                .disabled(!canShowDSR)
                                .frame(minWidth: 160)
                            Button(role: .destructive) {
                                resetScanner()
                            } label: {
                                Label("Reset", systemImage: "arrow.counterclockwise")
                            }.frame(minWidth: 160)

                            // Somewhere in your button action:
                        }   .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                        HStack(spacing: 10) {
                            Button("Print DSR Img") {
                                guard let m = dsrMetrics else { return }
                                
                                let img  = DSRReportImageRenderer.makeImage(from: m)
                                StarPrinterManager.queueImage(img) { result in
                                    print("Printer:", result)   // optional debug
                                }
                            }.disabled(!canShowDSR)
                                .frame(minWidth: 160)
                            .disabled(dsrMetrics == nil)
                            Button("Print DSR Txt") {
                                guard let m = dsrMetrics else { return }
                                // 1️⃣ Flatten your metrics into the dictionary form
                                let flat = m.asDict
                                // 2️⃣ Call the new generator overload
                                let img = DSRReceiptGenerator.makeImage(from: flat)
                                StarPrinterManager.queueImage(img) { result in
                                    print("Printer:", result)
                                }
                            }.disabled(!canShowDSR)
                                .frame(minWidth: 160)
                            
                            
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
                }
                
                // MARK: – Action Section
                DisclosureGroup("Debug") {
                    HStack(spacing: 15) {
                        Button("Show Raw OCR") { showRaw = true }
                            .disabled(rawText.isEmpty)
                            .buttonStyle(.bordered)

                        Button("Show POS Parse") { showPOS = true }
                            .disabled(parsedSections.isEmpty)
                            .buttonStyle(.bordered)
                    }
                    .padding(.top, 8)
                }
                .accentColor(.primary)
            .padding()
        }
        .fullScreenCover(isPresented: $showWeScanCamera) {
            WeScanScanner(source: .camera) { img in pickedImage = img }
                .ignoresSafeArea()
                .hideTabBar()
        }

        .fullScreenCover(isPresented: $showWeScanGallery,
                         onDismiss: { galleryRawImage = nil }) {
            if let raw = galleryRawImage {
                WeScanScanner(source: .image(raw)) { img in pickedImage = img }
                    .ignoresSafeArea()
                    .hideTabBar()
            }
        }
        .sheet(isPresented: $showImagePicker) {
            // ImagePicker still uses a binding
            ImagePicker(selectedImage: $galleryRawImage)
        }
        .onChange(of: galleryRawImage) { img in
            // when user picks photo, open WeScan editor
            if img != nil { showWeScanGallery = true }
        }



        .onChange(of: pickedImage) { img in
            guard let img else { return }
            isProcessing   = true
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
        .alert("DSR Report Created", isPresented: $showDSRCreatedAlert) {
            Button("OK", role: .cancel) { }
        }

    }
    // MARK: – Reset helper  ← add this inside DSRScannerView, BEFORE body
    private func resetScanner() {
        timeoutTask?.cancel()
        timeoutTask = nil

        pickedImage      = nil
        isProcessing     = false

        rawText          = ""
        parsedSections   = []
        dsrMetrics       = nil

        showRaw          = false
        showPOS          = false
        showDSR          = false
        showErrorAlert   = false
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

                self.dsrMetrics = DSRMetrics.from(parsed: dict)
                self.isProcessing = false

                if canShowDSR {
                    // ** Toggle success alert **
                    self.showDSRCreatedAlert = true
                } else {
                    self.showErrorAlert = true
                    }
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
