import SwiftUI

struct DSRReportView: View {
    let m: DSRMetrics

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                sectionTable(
                    title: "Section A",
                    rows: [
                        ("NET SALES", m.netSales, false),
                        ("FRY SOCIETY LOADS", nil, false),
                        ("GST & HST", m.gstHst, false),
                        ("MANITOBA PST", nil, false),
                        ("TOTAL A", m.totalA, true)
                    ]
                )

                sectionTable(
                    title: "Section B",
                    rows: [
                        ("CASH FLOAT INCREASE (DECREASE)", nil, false),
                        ("AGGREGATORS", m.aggregators, false),
                        ("PAYOUTS, GST / HST NOT INCLUDED", nil, false),
                        ("GST / HST ON PAYOUTS", nil, false),
                        ("VISA", m.visa, false),
                        ("MASTERCARD", m.mastercard, false),
                        ("AMERICAN EXPRESS", m.amex, false),
                        ("DEBIT CARD", m.debit, false),
                        ("BANK DEPOSIT", m.bankDeposit, false),
                        ("FRY SOCIETY PAYMENTS", nil, false),
                        ("NON-CASH COUPONS/REWARDS", nil, false),
                        ("GIVEX $ +/-", m.givex, false),
                        ("TOTAL B", m.totalB, true)
                    ]
                )

                sectionTable(
                    title: "Cash Difference",
                    rows: [
                        ("CASH DIFFERENCE", m.cashDifference, true)
                    ]
                )
            }
            .padding()
        }
    }

    /// Bordered 2-column table layout
    func sectionTable(title: String, rows: [(String, Double?, Bool)]) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(6)
                .background(Color.gray.opacity(0.2))
                .border(Color.black, width: 1)

            ForEach(rows.indices, id: \.self) { i in
                HStack(spacing: 0) {
                    tableCell(rows[i].0, isLabel: true, bold: rows[i].2)
                    
                    // vertical divider
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 1)

                    tableCell(rows[i].1.map { format($0) } ?? "", isLabel: false, bold: rows[i].2)
                }
                .frame(minHeight: 40)
                .border(Color.black, width: 1)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .shadow(radius: 2)
    }

    /// Label or Value box
    func tableCell(_ text: String, isLabel: Bool, bold: Bool) -> some View {
        Text(text)
            .fontWeight(bold ? .semibold : .regular)
            .font(.system(size: 14))
            .minimumScaleFactor(0.6)
            .lineLimit(nil)
            .multilineTextAlignment(isLabel ? .leading : .trailing)
            .padding(6)
            .frame(minWidth: 100, maxWidth: .infinity, alignment: isLabel ? .leading : .trailing)
    }

    /// Currency formatting helper
    func format(_ val: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: val)) ?? "\(val)"
    }
}
