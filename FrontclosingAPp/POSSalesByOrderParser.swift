import Foundation

struct POSSalesByOrder {

    struct Result {
        let values: [String: [String: Double]]
        let displayOrder: [String: [String]]
    }

    static func parse(raw: String) -> Result {

        var values = [String: [String: Double]]()
        var order  = [String: [String]]()

        // ── 1. keep everything from “eat in” onward ─────────
        let lower   = raw.lowercased()
        let start   = lower.range(of: "eat in")?.lowerBound ?? lower.startIndex
        let trimmed = lower[start...]

        // ── 2. split into cleaned lines ─────────────────────
        let lines = trimmed
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // ── 3. state machine over the lines ─────────────────
        var currentSection: String? = nil
        let headers = ["eat in", "delivery", "take out"]
        let rx = try! NSRegularExpression(   // accepts commas now ⬇︎
            pattern: #"^(.*?)\s+\(?\$([\d,]+\.\d{2})\)?$"#,
            options: [.caseInsensitive]
        )

        for line in lines {

            // ── section headers ─────────────
            if headers.contains(line) {
                currentSection = line
                values[line] = [:]
                order[line]  = []
                continue
            }

            // ── sentinel for the “tax” block ─
            if line.contains("hst 5%") {
                currentSection = "end"
                values["end"] = [:]
                order["end"]  = []
                continue        // don’t regex-match this line
            }

            // ── skip until we hit a header ───
            guard let section = currentSection else { continue }

            // ── regex match for “Label  $n.nn” ─
            let nsRange = NSRange(location: 0, length: line.utf16.count)
            guard let m = rx.firstMatch(in: line, range: nsRange) else { continue }

            guard
                let labelR  = Range(m.range(at: 1), in: line),
                let amountR = Range(m.range(at: 2), in: line)
            else { continue }

            var label  = line[labelR].trimmingCharacters(in: .whitespaces)
            var amount = Double(line[amountR].replacingOccurrences(of: ",", with: "")) ?? 0

            if line.contains("(") && line.contains(")") { amount *= -1 }

            if label == "rounded", values[section]!.keys.contains("rounded") {
                label = "rounded2"
            }

            values[section]![label] = amount
            order [section]!.append(label)
        }

        return Result(values: values, displayOrder: order)
    }
}
