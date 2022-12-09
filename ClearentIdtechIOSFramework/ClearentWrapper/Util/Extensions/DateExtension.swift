//
//  DateExtension.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 25.11.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

extension Date {
    func dateOnlyToString(format: String = "yyyy-MM-dd") -> String {
        let formatter = utcDateFormatter()
        formatter.dateStyle = .short
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    func timeToString(format: String = "HH:mm:ss 'UTC'") -> String {
        let formatter = utcDateFormatter()
        formatter.dateStyle = .short
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    func dateAndTimeToString(format: String = "yyyy-MM-dd HH:mm") -> String {
        let formatter = utcDateFormatter()
        formatter.dateStyle = .short
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    private func utcDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }
}
