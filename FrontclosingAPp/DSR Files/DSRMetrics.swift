import Foundation

struct DSRMetrics {
    // MARK: - Section A
    var netSales: Double?
    var gstHst: Double?
    var totalA: Double?

    // MARK: - Section B
    var aggregators: Double?
    var visa: Double?
    var mastercard: Double?
    var amex: Double?
    var debit: Double?
    var bankDeposit: Double?
    var givex: Double?
    var totalB: Double?

    // MARK: - Final Result
    var cashDifference: Double?

    static func from(parsed: [String: [String: Double]]) -> DSRMetrics? {
        func val(_ section: String, _ key: String) -> Double {
            parsed[section]?[key] ?? 0
        }

        let net    = parsed["end"]?["net"]
        let tax    = parsed["end"]?["total taxes"]
        guard let netSales = net, let gstHst = tax else { return nil }

        let visa       = val("eat in", "visa") + val("take out", "visa")
        let mastercard = val("eat in", "mastercard") + val("take out", "mastercard")
        let amex       = val("eat in", "amex") + val("take out", "amex")
        let debit      = val("eat in", "debit") + val("take out", "debit")
        let cash       = val("eat in", "cash") + val("take out", "cash")
        let givex      = val("eat in", "givex") + val("take out", "givex")
        let aggregators = parsed["delivery"]?["sales"] ?? 0

        let totalA = netSales + gstHst
        let totalB = aggregators + visa + mastercard + amex + debit + cash + givex
        let diff   = totalB - totalA

        return DSRMetrics(
            netSales: netSales,
            gstHst: gstHst,
            totalA: totalA,
            aggregators: aggregators,
            visa: visa,
            mastercard: mastercard,
            amex: amex,
            debit: debit,
            bankDeposit: cash,
            givex: givex,
            totalB: totalB,
            cashDifference: diff
        )
    }
}
