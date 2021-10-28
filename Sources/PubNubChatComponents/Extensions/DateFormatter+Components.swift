//
//  DateFormatter+Components.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2021 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

extension DateFormatter {
  public static var messageInline: DateFormatter {
    let formatter = DateFormatter()
    formatter.doesRelativeDateFormatting = true
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
  }
  
  
  public static func messageInline(for date: Date) -> DateFormatter {
    let formatter = DateFormatter()
    switch true {
    case Calendar.current.isDateInToday(date) || Calendar.current.isDateInYesterday(date):
      formatter.doesRelativeDateFormatting = true
      formatter.dateStyle = .short
      formatter.timeStyle = .short
    case Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear):
      formatter.dateFormat = "EEEE hh:mm"
    case Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year):
      formatter.dateFormat = "E, d MMM, hh:mm"
    default:
      formatter.dateFormat = "MMM d, yyyy, hh:mm"
    }
    return formatter
  }
}
