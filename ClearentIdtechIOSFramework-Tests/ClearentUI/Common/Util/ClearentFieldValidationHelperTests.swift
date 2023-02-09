//
//  ClearentFieldValidationHelperTests.swift
//  XplorPayMobileTests
//
//  Created by Carmen Jurcovan on 15.09.2022.
//

import XCTest
@testable import ClearentIdtechIOSFramework

class ClearentFieldValidationHelperTests: XCTestCase {

    func testIsCardNumberValid_true() {
        // Given
        let validPaymentItem = CardNoItem()
        let validValues = ["4485383550284604", "5454422955385717", "6011574229193527", "348570250878868"]

        validValues.forEach {
            // When
            validPaymentItem.enteredValue = $0
            
            // Then
            XCTAssertTrue(ClearentFieldValidationHelper.isCardNumberValid(item: validPaymentItem))
        }
    }
    
    func testIsCardNumberValid_false() {
        // Given
        let invalidPaymentItem = CardNoItem()
        let invalidValues = ["", "4485383550284622", "5454422955385735", "6011574229193581", "348570250878811", "1234123412341234", "1234"]
        
        invalidValues.forEach {
            // When
            invalidPaymentItem.enteredValue = $0
            
            // Then
            XCTAssertFalse(ClearentFieldValidationHelper.isCardNumberValid(item: invalidPaymentItem))
        }
    }
    
    func testIsSecurityCodeValid_true() {
        // Given
        let validPaymentItem = SecurityCodeItem()
        let validValues = ["1111", "123"]
        
        validValues.forEach {
            // When
            validPaymentItem.enteredValue = $0
            
            // Then
            XCTAssertTrue(ClearentFieldValidationHelper.isSecurityCodeValid(item: validPaymentItem))
        }
    }
    
    func testIsSecurityCodeValid_false() {
        // Given
        let invalidPaymentItem = SecurityCodeItem()
        let invalidValues = ["", "1", "12", "12345", "123 4"]
        
        invalidValues.forEach {
            // When
            invalidPaymentItem.enteredValue = $0
            
            // Then
            XCTAssertFalse(ClearentFieldValidationHelper.isSecurityCodeValid(item: invalidPaymentItem))
        }
    }
    
    func testIsCardHolderFirstNameValid_true() {
        // Given
        let validPaymentItem = CardholderFirstNameItem()
        let validValues = ["", "john", "john-matt", "john matt"]
        
        validValues.forEach {
            // When
            validPaymentItem.enteredValue = $0
            
            // Then
            XCTAssertTrue(ClearentFieldValidationHelper.isCardholderNameValid(item: validPaymentItem))
        }
    }
    
    func testIsCardHolderFirstNameValid_false() {
        // Given
        let invalidPaymentItem = CardholderFirstNameItem()
        let invalidValues = ["1a", "john]", "john.", "john_", "johnqewrtyuiosfdghjkvcbnmfdghjrtryuifghjbvcbndfghjohnq"]
        
        invalidValues.forEach {
            // When
            invalidPaymentItem.enteredValue = $0
            
            // Then
            XCTAssertFalse(ClearentFieldValidationHelper.isCardholderNameValid(item: invalidPaymentItem))
        }
    }
    
    func testIsZipValid_true() {
        // Given
        let validPaymentItem = BillingZipCodeItem()
        let validValues = ["12345", "12345-1234", ""]
        
        validValues.forEach {
            // When
            validPaymentItem.enteredValue = $0
            
            // Then
            XCTAssertTrue(ClearentFieldValidationHelper.isZipValid(item: validPaymentItem))
        }
    }
    
    func testIsZipValid_false() {
        // Given
        let invalidPaymentItem = BillingZipCodeItem()
        let invalidValues = ["1234", "1234567890", "1bcde", "12345-12345", "1234_"]
        
        invalidValues.forEach {
            print("item: \($0)")
            // When
            invalidPaymentItem.enteredValue = $0
            
            // Then
            XCTAssertFalse(ClearentFieldValidationHelper.isZipValid(item: invalidPaymentItem))
        }
    }

    func testHideCardNumber_success() {
        // Given
        let paymentItem = CardNoItem()
        paymentItem.enteredValue = "4111 1111 1111 1111"
        paymentItem.isValid = true

        // When
        ClearentFieldValidationHelper.hideCardNumber(sender: UITextField(), item: paymentItem)
        
        // Then
        XCTAssertEqual(paymentItem.hiddenValue, "**** **** **** 1111")
    }
    
    func testHideCardNumber_failure() {
        // Given
        let paymentItem = CardNoItem()
        paymentItem.enteredValue = "4111 1111 1111 1111"
        paymentItem.isValid = false

        // When
        ClearentFieldValidationHelper.hideCardNumber(sender: UITextField(), item: paymentItem)
        
        // Then
        XCTAssertNil(paymentItem.hiddenValue)
    }
    
    func testHideSecurityCode_success() {
        // Given
        let paymentItem = SecurityCodeItem()
        paymentItem.enteredValue = "123"
        paymentItem.isValid = true

        // When
        ClearentFieldValidationHelper.hideSecurityCode(sender: UITextField(), item: paymentItem)
        
        // Then
        XCTAssertEqual(paymentItem.hiddenValue, "***")
    }
    
    func testHideSecurityCode_failure() {
        // Given
        let paymentItem = SecurityCodeItem()
        paymentItem.enteredValue = "123"
        paymentItem.isValid = false

        // When
        ClearentFieldValidationHelper.hideSecurityCode(sender: UITextField(), item: paymentItem)
        
        // Then
        XCTAssertNil(paymentItem.hiddenValue)
    }
}
