//
//  DSRMetrics.swift
//
//  Created by Shubham on 2025‑05‑xx
//

import Foundation
import UIKit

// ────────────────────────────────────────────────────────────
// MARK: - Data model
// ────────────────────────────────────────────────────────────
struct DSRMetrics {

    // ── Section A
    var netSales:        Double?
    var fryLoads:        Double?
    var gstHst:          Double?
    var manitobaPst:     Double?
    var totalA:          Double?

    // ── Section B
    var cashFloatDelta:  Double?
    var aggregators:     Double?
    var payouts:         Double?
    var gstOnPayouts:    Double?
    var visa:            Double?
    var mastercard:      Double?
    var amex:            Double?
    var debit:           Double?
    var bankDeposit:     Double?
    var fryPayments:     Double?
    var nonCash:         Double?
    var givex:           Double?
    var totalB:          Double?

    // ── Final
    var cashDifference:  Double?
}

// ────────────────────────────────────────────────────────────
// MARK: - Parser  (Vision / OCR dictionary ➜ DSRMetrics)
// ────────────────────────────────────────────────────────────
extension DSRMetrics {

    /// Build a `DSRMetrics` from the dictionary your OCR pipeline spits out.
    ///
    /// Adjust the **section / key** strings so they match your real JSON.
    static func from(parsed dict: [String: [String: Double]]) -> DSRMetrics? {

        // Helper that keeps nil if the key is missing
        func get(_ section: String, _ key: String) -> Double? {
            dict[section]?[key]
        }

        // Add two optionals, but preserve nil if both are nil
        func add(_ a: Double?, _ b: Double?) -> Double? {
            switch (a, b) {
            case (nil, nil): return nil
            default:         return (a ?? 0) + (b ?? 0)
            }
        }

        // ── Mandatory (fail early if absent)
        guard
            let net   = dict["end"]?["net"],                // TODO key
            let taxes = dict["end"]?["total taxes"]         // TODO key
        else { return nil }

        // ── Optional
        let fryLoads    = dict["end"]?["fry society loads"] // TODO key
        let mbPst       = dict["end"]?["manitoba pst"]      // TODO key

        let cashFloat   = dict["cash"]?["float delta"]      // TODO key
        let aggregators = dict["delivery"]?["sales"]        // TODO key
        let payouts     = dict["cash"]?["payouts"]          // TODO key
        let gstPayout   = dict["cash"]?["gst on payouts"]   // TODO key

        let visa        = add(get("eat in","visa"),        get("take out","visa"))
        let mastercard  = add(get("eat in","mastercard"),  get("take out","mastercard"))
        let amex        = add(get("eat in","amex"),        get("take out","amex"))
        let debit       = add(get("eat in","debit"),       get("take out","debit"))
        let bankDep     = add(get("eat in","cash"),        get("take out","cash"))
        let fryPay     = add(get("eat in","fry society cash/loyalty"),        get("take out","fry society cash/loyalty"))
        let nonCash     = dict["cash"]?["non cash coupons"]     // TODO key
        let givex       = add(get("eat in","givex"),       get("take out","givex"))

        // ── Totals
        let totalA = [net, fryLoads, taxes, mbPst]
                      .compactMap { $0 }.reduce(0, +)

        let totalB = [
            cashFloat, aggregators, payouts, gstPayout,
            visa, mastercard, amex, debit, bankDep,
            fryPay, nonCash, givex
        ].compactMap { $0 }.reduce(0, +)

        return DSRMetrics(
            netSales:        net,
            fryLoads:        fryLoads,
            gstHst:          taxes,
            manitobaPst:     mbPst,
            totalA:          totalA,

            cashFloatDelta:  cashFloat,
            aggregators:     aggregators,
            payouts:         payouts,
            gstOnPayouts:    gstPayout,
            visa:            visa,
            mastercard:      mastercard,
            amex:            amex,
            debit:           debit,
            bankDeposit:     bankDep,
            fryPayments:     fryPay,
            nonCash:         nonCash,
            givex:           givex,
            totalB:          totalB,

            cashDifference:  totalB - totalA
        )
    }
}

extension DSRMetrics {
    /// Flatten into `[String : Double]` for inter-module or dynamic use.
    /// Nil values are simply omitted (so the consumer can `?? 0` if needed).
    var asDict: [String: Double] {
        var d: [String: Double] = [:]

        // Section A
        if let v = netSales        { d["netSales"]        = v }
        if let v = fryLoads        { d["fryLoads"]        = v }
        if let v = gstHst          { d["gstHst"]          = v }
        if let v = manitobaPst     { d["manitobaPst"]     = v }
        d["totalA"] = totalA ?? 0

        // Section B
        if let v = cashFloatDelta  { d["cashFloatDelta"]  = v }
        if let v = aggregators     { d["aggregators"]     = v }
        if let v = payouts         { d["payouts"]         = v }
        if let v = gstOnPayouts    { d["gstOnPayouts"]    = v }
        if let v = visa            { d["visa"]            = v }
        if let v = mastercard      { d["mastercard"]      = v }
        if let v = amex            { d["amex"]            = v }
        if let v = debit           { d["debit"]           = v }
        if let v = bankDeposit     { d["bankDeposit"]     = v }
        if let v = fryPayments     { d["fryPayments"]     = v }
        if let v = nonCash         { d["nonCash"]         = v }
        if let v = givex           { d["givex"]           = v }
        d["totalB"] = totalB ?? 0

        // Final
        if let v = cashDifference  { d["cashDifference"]  = v }

        return d
    }
}
