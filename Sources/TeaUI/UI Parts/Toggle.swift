//
//  Toggle.swift
//  TeaUI
//
//  Created by Kai Driessen on 2025-08-28.
//

public enum ToggleStyle: Sendable {
	case checkbox
	case `switch`
	
	var value: [Bool: String] {
		switch self {
			case .checkbox:
				[true: "■", false: " "]
			case .switch:
				[true: "-\u{1B}[32m•\u{1B}[0m", false: "\u{1B}[31m•\u{1B}[0m-"]
		}
	}
}


/// A toggle can be switched on or off. It can look like a checkbox or a switch.
public struct Toggle: FocusableModel {
	public var isFocused = false
	public var isChecked: Bool
	let style: ToggleStyle
	static let bounds = [true: (l: "\u{1B}[36m[\u{1B}[0m", r: "\u{1B}[36m]\u{1B}[0m"), false: (l: "[", r: "]")]
	
	public init(style: ToggleStyle = .checkbox, checked: Bool = false) {
		self.style = style
		self.isChecked = checked
	}
	
	public func update(_ event: any Event) -> (any Model, Command?) {
		switch event {
			case let event as KeyPress: switch event {
				case .return, .space:
					var newState = self
					newState.isChecked.toggle()
					return (newState, nil)
				default: break
			}
			default: break
		}
		
		return (self, nil)
	}
	
	public var body: String {
		let box = Toggle.bounds[isFocused]!
		return box.l + style.value[isChecked]! + box.r
	}
}
