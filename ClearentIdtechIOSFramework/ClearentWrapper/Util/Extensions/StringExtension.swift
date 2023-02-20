//
//  StringExtension.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 11.10.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

extension String {
    func setTwoDecimals() -> String {
        let valueArray = self.split(separator: ".")
        if valueArray.last?.count == 1, valueArray.count > 1 {
            return self + "0"
        }
        return self
    }
    
    func toDateUseShortFormat() -> Date? {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: self)
    }
}
