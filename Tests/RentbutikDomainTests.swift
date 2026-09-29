import XCTest
@testable import RentbutikDomain

final class RentbutikDomainTests: XCTestCase {
    func testMinuteTariffUsesActualMinutes() {
        XCTAssertEqual(RidePricing.quote(tariff: .minute, elapsed: 61).total, Decimal(string: "1.50"))
    }
    func testPlanConsumesOnlyMinuteTariffAndOnlyAvailableMinutes() {
        let quote = RidePricing.quote(tariff: .minute, elapsed: 600, availableMinutes: 6)
        XCTAssertEqual(quote, RideQuote(total: 2, planMinutes: 6))
        XCTAssertEqual(RidePricing.quote(tariff: .hour, elapsed: 600, availableMinutes: 100).planMinutes, 0)
    }
    func testHourlyBoundariesAndDailyCap() {
        XCTAssertEqual(RidePricing.quote(tariff: .hour, elapsed: 3600).total, 16)
        XCTAssertEqual(RidePricing.quote(tariff: .hour, elapsed: 3601).total, 31)
        XCTAssertEqual(RidePricing.quote(tariff: .hour, elapsed: 5 * 3600).total, 61)
        XCTAssertEqual(RidePricing.quote(tariff: .day, elapsed: 25 * 3600).total, 76)
        XCTAssertEqual(RidePricing.quote(tariff: .day, elapsed: 49 * 3600).total, 136)
    }
    func testBookedBlockAndRentalGrace() {
        XCTAssertEqual(RidePricing.quote(tariff: .day, elapsed: 60, booked: 48 * 3600).total, 121)
        XCTAssertEqual(RidePricing.rentalDays(duration: 26 * 3600), 1)
        XCTAssertEqual(RidePricing.rentalDays(duration: 26 * 3600 + 1), 2)
    }
    func testDeclineDoesNotSpendWallet() {
        var book = PaymentBook(), balance: Decimal = 5
        XCTAssertEqual(book.charge(id: "ride", amount: 16, walletBalance: &balance,
                                   walletFirst: true, cardLabel: "Visa", cardDeclines: true), .declined)
        XCTAssertEqual(balance, 5)
        XCTAssertTrue(book.receipts.isEmpty)
    }
    func testRetryChargesOnceAndRefundRestoresOriginalSplitOnce() {
        var book = PaymentBook(), balance: Decimal = 5
        let first = book.charge(id: "ride", amount: 16, walletBalance: &balance,
                                walletFirst: true, cardLabel: "Visa", cardDeclines: false)
        let retry = book.charge(id: "ride", amount: 16, walletBalance: &balance,
                                walletFirst: true, cardLabel: "Mastercard", cardDeclines: false)
        XCTAssertEqual(first, retry)
        XCTAssertEqual(balance, 0)
        let refund = book.refund(id: "ride", walletBalance: &balance)
        XCTAssertEqual(refund?.wallet, 5)
        XCTAssertEqual(refund?.card, 11)
        XCTAssertEqual(refund?.cardLabel, "Visa")
        XCTAssertEqual(balance, 5)
        XCTAssertNil(book.refund(id: "ride", walletBalance: &balance))
        XCTAssertEqual(balance, 5)
    }
    func testIdempotencyKeyCannotBeReusedForDifferentAmount() {
        var book = PaymentBook(), balance: Decimal = 100
        _ = book.charge(id: "booking", amount: 20, walletBalance: &balance,
                        walletFirst: true, cardLabel: "Visa", cardDeclines: false)
        XCTAssertEqual(book.charge(id: "booking", amount: 30, walletBalance: &balance,
                                   walletFirst: true, cardLabel: "Visa", cardDeclines: false), .conflict)
        XCTAssertEqual(balance, 80)
    }
}
