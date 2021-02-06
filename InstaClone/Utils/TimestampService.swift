//
//  TimestampService.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 2/2/21.
//

import Foundation
import Firebase

struct TimestampService{
    
    static var df = DateComponentsFormatter()
    
    static func getStringDate(timeStamp: Timestamp, unitsStyle: DateComponentsFormatter.UnitsStyle) -> String?{
        TimestampService.df.allowedUnits = [.second, .minute, .hour, .day, .weekOfMonth]
        TimestampService.df.maximumUnitCount = 1
        TimestampService.df.unitsStyle = unitsStyle
        return TimestampService.df.string(from: timeStamp.dateValue(), to: Date())
    }
}


