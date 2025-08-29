//
//  Button.swift
//  TeaUI
//
//  Created by Kai Driessen on 2025-08-27.
//

public struct Button: FocusableModel {
	public var isFocused = false
	
	let label: String
	let onPressCommand: any Command
	
	public init(label: String, pressCommand: any Command) {
		self.label = label
		self.onPressCommand = pressCommand
	}
	
	public func update(_ event: any Event) -> (any Model, Command?) {
		if let key = event as? KeyPress, key == .return || key == .space {
			return (self, onPressCommand)
		}
		
		return (self, nil)
	}
	
	public var body: String {
		"\(isFocused ? "\u{1B}[7m" : "")[\(label)]\(isFocused ? "\u{1B}[0m" : "")"
	}
}
