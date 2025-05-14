//
//  PrintManager.swift
//  Handles printing of SwiftUI views to Star Micronics TSP100III Bluetooth printer
//

import Foundation
import SwiftUI
import UIKit
import StarIO10

/// Manages discovery and printing of a receipt UIImage via StarIO10.
struct StarPrinterManager {
    static func printReceipt(
        employeeName: String,
        currentDate: String,
        tableTitle: String,
        individualDenominationCounts: [Double: Int],
        bundleDenominationCounts: [Double: Int],
        completion: @escaping (String) -> Void
    ) {
        let image = ReceiptGenerator.generateReceiptImage(
            employeeName: employeeName,
            currentDate: currentDate,
            tableTitle: tableTitle,
            individualDenominationCounts: individualDenominationCounts,
            bundleDenominationCounts: bundleDenominationCounts
        )
        printImage(receiptImage: image, completion: completion)
    }

    private static func printImage(
        receiptImage: UIImage,
        completion: @escaping (String) -> Void
    ) {
        Task {
            do {
                let discoveryManager = try StarDeviceDiscoveryManagerFactory
                    .create(interfaceTypes: [.bluetooth])
                discoveryManager.discoveryTime = 5000
                
                var foundPrinter: StarPrinter?
                let sem = DispatchSemaphore(value: 0)

                class Delegate: NSObject, StarDeviceDiscoveryManagerDelegate {
                    let sem: DispatchSemaphore
                    var onPrinterFound: ((StarPrinter) -> Void)?
                    init(_ sem: DispatchSemaphore) { self.sem = sem }
                    func manager(_ m: StarDeviceDiscoveryManager, didFind p: StarPrinter) {
                        onPrinterFound?(p)
                    }
                    func managerDidFinishDiscovery(_ m: StarDeviceDiscoveryManager) {
                        sem.signal()
                    }
                }
                let delegate = Delegate(sem)
                delegate.onPrinterFound = { p in foundPrinter = p }
                discoveryManager.delegate = delegate
                try discoveryManager.startDiscovery()
                _ = sem.wait(timeout: .now() + 6)

                guard let printer = foundPrinter else {
                    completion("No Bluetooth printer found.")
                    return
                }

                let builder = StarXpandCommand.StarXpandCommandBuilder()
                _ = builder.addDocument(
                    StarXpandCommand.DocumentBuilder()
                        .addPrinter(
                            StarXpandCommand.PrinterBuilder()
                                .actionPrintImage(
                                    StarXpandCommand.Printer.ImageParameter(
                                        image: receiptImage,
                                        width: 406
                                    )
                                )
                                .actionCut(.partial)
                        )
                )
                let commands = builder.getCommands()

                try await printer.open()
                try await printer.print(command: commands)
                try await printer.close()

                completion("Receipt printed successfully.")
            } catch let error as StarIO10Error {
                var message = error.localizedDescription

                switch error {
                // 1) Bluetooth‐off is signaled as .illegalDeviceState with code .bluetoothUnavailable
                case .illegalDeviceState(let msg, let code)
                    where code == .bluetoothUnavailable:
                    message = "Bluetooth is off or unavailable. Please enable Bluetooth."

                // 2) Communication errors
                case .communication(let msg, _):
                    message = "Communication error with printer: \(msg)"

                // 3) No printer found
                case .notFound(let msg, _):
                    message = "Printer not found: \(msg)"

                // 4) Printer in unprintable state – capture message and status
                case .unprintable(let msg, _, let status):
                    if let status = status {
                        if status.coverOpen {
                            message = "Printer cover is open."
                        } else if status.paperEmpty {
                            message = "Printer is out of paper."
                        } else {
                            message = "Printer cannot print: \(msg)"
                        }
                    } else {
                        message = "Printer cannot print: \(msg)"
                    }

                // 5) Any other StarIO10Error
                default:
                    message = "Printer error: \(error)"
                }

                completion(message)
            } catch {
                completion("Unknown error: \(error.localizedDescription)")
            }        }
    }
}

