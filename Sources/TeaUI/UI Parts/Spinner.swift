//
//  Spinner.swift
//  TeaUI
//
//  Created by Kai Driessen on 2025-08-08.
//

public struct Spinner: FocusableModel {
	public var value: Int {
		didSet {
			if !range.contains(value) { // clamp within bounds
				if value > range.upperBound {
					value = range.upperBound
				} else {
					value = range.lowerBound
				}
			}
		}
	}
	public var isFocused: Bool = false {
		didSet {
			didTypeLastEvent = false
		}
	}
	let step: Int
	let range: ClosedRange<Int>
	let initialValue: Int

	var didTypeLastEvent: Bool = false
	
	public init(value: Int = 0, step: Int = 1, range: ClosedRange<Int> = 0...250) {
		self.value = value
		self.initialValue = value
		self.step = step
		self.range = range
	}
	
	
	public func update(_ event: any Event) -> (any Model, Command?) {
		var newState = self
		
		switch event {
			case let event as KeyPress: switch event {
				case .return:
					return (self, FocusCommand.next)
				case .left:
					newState.value -= step
				case .right:
					newState.value += step
				case .ascii(let char):
					guard let num = Int(String(char)) else {
						break
					}
					
					if didTypeLastEvent {
						// add typed number to the end
						if let newVal = Int(String(newState.value) + String(num)) {
							newState.value = newVal
						}
						return (newState, nil)
					} else {
						newState.value = (num)
						newState.didTypeLastEvent = true
					}
					return (newState, nil)
						
				case .delete:
					newState.value = initialValue
				default: break
			}
			default: break
		}
		
		newState.didTypeLastEvent = false
		return (newState, nil)
	}
	
	public var body: String {
		let arrows = isFocused ? (
			value != range.lowerBound ? "\u{001B}[36m⯇\u{001B}[0m \u{001B}[7m" : "⯇ \u{001B}[7m",
			value != range.upperBound ? "\u{001B}[0m \u{001B}[36m⯈\u{001B}[0m" : "\u{001B}[0m ⯈"
		) : ("⯇ ", " ⯈")
		return "\(arrows.0)\(value)\(arrows.1)"
	}
}
