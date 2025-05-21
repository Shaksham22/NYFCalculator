import Foundation
import UIKit

/// A single print request.
struct PrintJob: Identifiable {
    let id = UUID()
    let image: UIImage
    let completion: (String) -> Void
}

/// Actor = thread-safe, runs one job at a time.
actor PrinterJobQueue {

    static let shared = PrinterJobQueue()          // global queue
    private init() {}

    private var isPrinting = false
    private var queue: [PrintJob] = []

    /// Add a job; start processing if idle.
    func enqueue(_ job: PrintJob) {
        queue.append(job)
        if !isPrinting {
            Task { await processQueue() }
        }
    }

    /// Pop & run jobs serially.
    private func processQueue() async {
        isPrinting = true
        defer { isPrinting = false }

        while !queue.isEmpty {
            let job = queue.removeFirst()
            await run(job)
        }
    }

    /// Calls your existing StarPrinterManager.printImage asynchronously.
    private func run(_ job: PrintJob) async {
        await withCheckedContinuation { cont in
            // Call the new signature without the 'receiptImage:' label
            StarPrinterManager.printImage(job.image) { message in
                job.completion(message)   // bubble result to caller
                cont.resume()             // go to next job
            }
        }
    }
}
