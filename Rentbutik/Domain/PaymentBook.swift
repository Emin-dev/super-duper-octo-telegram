import Foundation

/// Local payment simulation; a real gateway must confirm every production operation.
/// Receipts preserve the original funding split so retries and refunds are exact.
struct PaymentBook: Codable {
    struct Receipt: Codable, Equatable {
        let id: String
        let wallet: Decimal
        let card: Decimal
        let cardLabel: String
        var refunded = false
    }
    enum Result: Equatable {
        case paid(Receipt)
        case declined
        case conflict
    }
    private(set) var receipts: [String: Receipt] = [:]

    mutating func charge(id: String, amount: Decimal, walletBalance: inout Decimal,
                         walletFirst: Bool, cardLabel: String, cardDeclines: Bool) -> Result {
        guard amount >= 0 else { return .conflict }
        if let receipt = receipts[id] {
            guard !receipt.refunded, receipt.wallet + receipt.card == amount else { return .conflict }
            return .paid(receipt)
        }
        let wallet = walletFirst ? min(max(0, walletBalance), amount) : 0
        let card = amount - wallet
        guard card == 0 || !cardDeclines else { return .declined }
        let receipt = Receipt(id: id, wallet: wallet, card: card, cardLabel: cardLabel)
        walletBalance -= wallet
        receipts[id] = receipt
        return .paid(receipt)
    }

    /// Returns nil on repeated refund, unknown payment, or already-refunded payment.
    mutating func refund(id: String, walletBalance: inout Decimal) -> Receipt? {
        guard var receipt = receipts[id], !receipt.refunded else { return nil }
        walletBalance += receipt.wallet
        receipt.refunded = true
        receipts[id] = receipt
        return receipt
    }
}
