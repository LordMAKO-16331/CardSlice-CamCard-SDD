//
//  CardSliceTests.swift
//  CardSliceTests
//
//  Created by 谢薇 on 2026/11/2.
//

import Testing
import Foundation
@testable import CardSlice

@MainActor
struct CardSliceTests {

    @Test func testCreateBusinessCard() async throws {
        let card = BusinessCardRecord(name: "Test User")
        #expect(card.name == "Test User")
        #expect(card.phones.isEmpty)
        #expect(card.emails.isEmpty)
    }
    
    @Test func testMultiplePhonesAndFax() async throws {
        let phones = [
            PhoneEntry(value: "123", type: .mobile),
            PhoneEntry(value: "456", type: .office),
            PhoneEntry(value: "789", type: .fax)
        ]
        let card = BusinessCardRecord(name: "Alice", phones: phones)
        
        #expect(card.phones.count == 3)
        #expect(card.phones.contains { $0.type == .fax })
        #expect(card.phones[2].value == "789")
    }
    
    @Test func testMultipleEmails() async throws {
        let emails = ["a@example.com", "b@example.com"]
        let card = BusinessCardRecord(name: "Bob", emails: emails)
        #expect(card.emails.count == 2)
        #expect(card.emails.contains("b@example.com"))
    }
    
    @Test func testMissingWebsite() async throws {
        let card = BusinessCardRecord(name: "Charlie")
        #expect(card.website == nil) // T09: 缺失 Website 时保持 nil
    }
    
    @Test func testOCRTraceability() async throws {
        let parsed = ParsedContactFields(name: "Parsed Name")
        let card = BusinessCardRecord(
            ocrRawText: "Raw Text Data",
            parsedFields: parsed,
            name: "Confirmed Name"
        )
        
        // OCR 原始文字、初始解析字段和最终字段互不覆盖 [DECISION]
        #expect(card.ocrRawText == "Raw Text Data")
        #expect(card.parsedFields?.name == "Parsed Name")
        #expect(card.name == "Confirmed Name")
    }
    
    @Test func testTagIdentity() async throws {
        let tag = TagRecord(name: "Work")
        let card = BusinessCardRecord(name: "Dave", tagIDs: [tag.id])
        
        #expect(card.tagIDs.count == 1)
        #expect(card.tagIDs.first == tag.id)
    }

}
