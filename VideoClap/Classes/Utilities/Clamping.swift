//
//  Clamping.swift
//  VideoClap
//
//  Created by lai001 on 2021/1/15.
//

import Foundation

@propertyWrapper
struct Clamping<Value: Comparable> {
  var value: Value
  let range: ClosedRange<Value>

  init(wrappedValue: Value, _ range: ClosedRange<Value>) {
    precondition(range.contains(wrappedValue))
    self.value = wrappedValue
    self.range = range
  }

  var wrappedValue: Value {
    get { value }
    set { value = min(max(range.lowerBound, newValue), range.upperBound) }
  }
}
