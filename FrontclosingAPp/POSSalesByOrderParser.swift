//  POSSalesByOrder.swift
//  Parses raw receipt text AND preserves the display order found
//
//  Result.values        → identical to your old finalhashmap
//  Result.displayOrder  → identical to your new finaldisplayorder

import Foundation

// MARK: – Public façade ─────────────────────────────────────────
struct POSSalesByOrder {

    struct Result {
        let values       : [String : [String : Double]]
        let displayOrder : [String : [String]]
    }

    /// Same entry point – now returns both the dictionary *and* the order list
    static func parse(raw: String) -> Result {

        // ---------- 1. Pre‑process -----------------------------------------
        let lower = raw.lowercased()
        guard let eatPos = lower.range(of: "eat in") else { return .init(values: [:], displayOrder: [:]) }
        let trimmed = String(lower[eatPos.lowerBound...])
        var lines: [Line] = trimmed
            .components(separatedBy: .newlines)
            .map { line -> Line in
                if line.hasPrefix("$") {
                    return .number(parseDollar(line))
                } else if line.hasPrefix("($") {
                    return .number(-parseDollar(line))
                } else {
                    return .word(line.trimmingCharacters(in: .whitespaces))
                }
            }

        // ---------- 2. Partition into blocks -------------------------------
        var blocks: [Block] = []
        var start = 0
        var firstNum: Int?
        var inNums = false

        for (i, l) in lines.enumerated() {
            switch (l, inNums) {
            case (.number, false):
                firstNum = i; inNums = true
            case (.word, true) where i != 0:
                let words   = Array(lines[start ..< (firstNum ?? i)]).compactMap(\.wordString)
                let numbers = Array(lines[(firstNum ?? i) ..< i]).compactMap(\.numberValue)
                blocks.append(Block(words: words, numbers: numbers))
                start = i; inNums = false
            default: break
            }
        }
        if let first = firstNum {
            let words   = Array(lines[start ..< first]).compactMap(\.wordString)
            let numbers = Array(lines[first ..< lines.count]).compactMap(\.numberValue)
            blocks.append(Block(words: words, numbers: numbers))
        }

        // ---------- 3. Parse every block & merge ---------------------------
        var finalValues : [String : [String : Double]] = [:]
        var finalOrder  : [String : [String]]          = [:]

        for block in blocks {
            let br = parseBlock(block)   // BlockResult (values + order)
            // merge values
            for (key, inner) in br.values {
                finalValues[key, default: [:]].merge(inner) { _, new in new }
            }
            // merge display order (append)
            for (key, ord) in br.order {
                finalOrder[key, default: []].append(contentsOf: ord)
            }
        }
        return Result(values: finalValues, displayOrder: finalOrder)
    }
}

// MARK: – Internal types & helpers ─────────────────────────────
private struct Block { let words: [String]; let numbers: [Double] }

private enum Line {
    case word(String); case number(Double)
    var wordString : String? { if case let .word(s)    = self { s }    else { nil } }
    var numberValue: Double? { if case let .number(n)  = self { n }    else { nil } }
}

private struct BlockResult {
    let values: [String : [String : Double]]
    let order : [String : [String]]
}

// ---------- Keywords (same lists as Python) -------------------
private let keywords1 = ["eat in", "delivery", "take out"]
private let keywords2 = ["hst 5%", "total taxes"]

// ---------- Block‑level parser (Python function1) -------------
private func parseBlock(_ block: Block) -> BlockResult {
    var values : [String : [String : Double]] = [:]
    var order  : [String : [String]]          = [:]

    var current: String?
    var offset = 0                            // ct in Python

    for (idx, word) in block.words.enumerated() {
        if keywords1.contains(word) {
            current = word
            values[current!] = [:]
            order [current!] = []
            offset -= 1
            continue
        }
        if keywords2.contains(word), values["end"] == nil {
            current = "end"
            values[current!] = [:]
            order [current!] = []
        }
        guard let key = current, idx + offset < block.numbers.count else { continue }
        values[key]?[word] = block.numbers[idx + offset]
        order [key]?.append(word)
    }
    return BlockResult(values: values, order: order)
}

// ---------- Dollar helpers ------------------------------------
private func parseDollar(_ s: String) -> Double {
    Double(
        s.trimmingCharacters(in: CharacterSet(charactersIn: "$()"))
         .replacingOccurrences(of: ",", with: "")
    ) ?? 0
}
