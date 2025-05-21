//
//  StarPrinterManager.swift
//  Generic image printer for Star Micronics TSP100III via StarIO10
//

import Foundation
import UIKit
import StarIO10


struct StarPrinterManager {
    
    /// Preferred entry point – enqueue a UIImage for printing.
    static func queueImage(
        _ image: UIImage,
        completion: @escaping (String) -> Void
    ) {
        let job = PrintJob(image: image, completion: completion)
        Task { await PrinterJobQueue.shared.enqueue(job) }
    }
    
    /// Print a UIImage immediately (synchronously w.r.t. the printer).
    /// You usually shouldn’t call this directly; use `queueImage`.
    static func printImage(
        _ image: UIImage,
        completion: @escaping (String) -> Void
    ) {
        Task {
            do {
                // 1. Discover Bluetooth printer
                let discovery = try StarDeviceDiscoveryManagerFactory
                    .create(interfaceTypes: [.bluetooth])
                discovery.discoveryTime = 5000
                
                var found: StarPrinter?
                let sem = DispatchSemaphore(value: 0)
                
                class Delegate: NSObject, StarDeviceDiscoveryManagerDelegate {
                    let sem: DispatchSemaphore
                    var onFound: ((StarPrinter) -> Void)?
                    init(_ s: DispatchSemaphore) { sem = s }
                    func manager(_ m: StarDeviceDiscoveryManager, didFind p: StarPrinter) { onFound?(p) }
                    func managerDidFinishDiscovery(_ m: StarDeviceDiscoveryManager) { sem.signal() }
                }
                let delegate = Delegate(sem)
                delegate.onFound = { found = $0 }
                discovery.delegate = delegate
                try discovery.startDiscovery()
                _ = sem.wait(timeout: .now() + 6)
                
                guard let printer = found else {
                    completion("No Bluetooth printer found.")
                    return
                }
                
                // 2. Build commands
                let builder = StarXpandCommand.StarXpandCommandBuilder()
                _ = builder.addDocument(
                    StarXpandCommand.DocumentBuilder()
                        .addPrinter(
                            StarXpandCommand.PrinterBuilder()
                                .actionPrintImage(
                                    StarXpandCommand.Printer.ImageParameter(
                                        image: image,
                                        width: Int(image.size.width)
                                    )
                                )
                                .actionCut(.partial)
                        )
                )
                
                // 3. Send to printer
                try await printer.open()
                try await printer.print(command: builder.getCommands())
                try await printer.close()
                
                completion("Print job completed.")
                
            } catch let e as StarIO10Error {
                completion(Self.humanMessage(from: e))
            } catch {
                completion("Unknown error: \(error.localizedDescription)")
            }
        }
    }
    
    // ───────── Optional legacy helper (delete when migrated) ─────────
    /// Keeps old calls compiling while you move generation into views.
    static func queueReceipt(
        employeeName: String,
        currentDate: String,
        tableTitle: String,
        individualDenominationCounts: [Double: Int],
        bundleDenominationCounts: [Double: Int],
        completion: @escaping (String) -> Void
    ) {
        let img = ReceiptGenerator.generateReceiptImage(
            employeeName: employeeName,
            currentDate: currentDate,
            tableTitle: tableTitle,
            individualDenominationCounts: individualDenominationCounts,
            bundleDenominationCounts: bundleDenominationCounts
        )
        queueImage(img, completion: completion)
    }
    
    // ─────────────────────────────────────────────────────────────
    //  Error → human-readable
    // ─────────────────────────────────────────────────────────────
    private static func humanMessage(from err: StarIO10Error) -> String {
        switch err {
        case .illegalDeviceState(_, let code) where code == .bluetoothUnavailable:
            return "Bluetooth is off or unavailable. Please enable Bluetooth."
        case .communication(let msg, _):
            return "Communication error with printer: \(msg)"
        case .notFound(let msg, _):
            return "Printer not found: \(msg)"
        case .unprintable(let msg, _, let status):
            if let s = status {
                if s.coverOpen  { return "Printer cover is open." }
                if s.paperEmpty { return "Printer is out of paper." }
            }
            return "Printer cannot print: \(msg)"
        default:
            return "Printer error: \(err)"
        }
    }
}
