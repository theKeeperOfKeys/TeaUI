//
//  TextField.swift
//  TeaUI
//
//  Created by Kai Driessen on 2025-08-07.
//

import Foundation

public struct TextField: FocusableModel {
	let label: String
	let maxChars: Int?
	let placeholder: String?
	public var isFocused = false
	public var value = ""
	
	
	public init(label: String, placeholder: String? = nil, maxChars: Int? = nil, value: String = "") {
		self.label = label
		self.placeholder = placeholder
		self.maxChars = maxChars
		self.value = value
	}
	
	
	public func update(_ event: any Event) -> (any Model, Command?) {
		var newState = self
		
		switch event {
			case let event as KeyPress: switch event {
				case .delete:
					if newState.value.popLast() == nil {
						// could not pop
						beep()
					}
				case .ascii(let char):
					if let maxChars {
						guard value.count < maxChars else {
							return (newState, nil)
						}
					}
					newState.value.append(char)
				case .space:
					if let maxChars {
						guard value.count < maxChars else {
							return (newState, nil)
						}
					}
					newState.value.append(" ")
				case .return:
					return (self, FocusCommand.next)
				default: break
			}
			default: break
		}
		
		return (newState, nil)
	}
	
	public var body: String {
		let cursor = isFocused ? "\u{1B}[5m\u{001B}[36m|\u{1B}[0m" : ""
		let labelFocus = isFocused ? ("\u{1B}[7m", "\u{1B}[0m") : ("", "")
		
		// I don't really like that there are always colour tags even if there is no placeholder...
		return "\(labelFocus.0)\(label)\(labelFocus.1): \(value.isEmpty ? "\u{1B}[90m" + (placeholder ?? "") + "\u{1B}[0m" : value + cursor)"
	}
}
