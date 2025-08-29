//
//  Selector.swift
//  TeaUI
//
//  Created by Kai Driessen on 2025-08-21.
//

public struct Selector: FocusableModel {
	public var isFocused = false
	/// The index of the currently selected options.
	public var selectionIdx: Int = 0
	/// The selected options.
	public var selected: String { options[selectionIdx] }
	/// The options to choose from.
	public let options: [String]

	
	public init(options: [String]) {
		self.options = options
	}
	
	
	public func update(_ event: any Event) -> (any Model, Command?) {
		switch event {
			case let event as KeyPress:
				var newState = self
				
				switch event {
					case .left:
						guard selectionIdx > 0 else {
							beep()
							return (self, nil)
						}
						
						newState.selectionIdx -= 1
						return (newState, nil)
						
					case .right:
						guard selectionIdx < options.count - 1 else {
							beep()
							return (self, nil)
						}
						newState.selectionIdx += 1
						
					case .delete:
						newState.selectionIdx = 0
						
					default: break
				}
				
				return (newState, nil)
			default: break
		}
		
		return (self, nil)
	}
	
	public var body: String {
		let selected = options[selectionIdx]
		let formattedSelected = isFocused ? "\u{001B}[7m" + selected + "\u{001B}[0m" : selected
		
		let isFirst = selectionIdx == 0
		let isLast = selectionIdx == options.count - 1
		
		let LArrow = !isFirst ? (isFocused ? "\u{001B}[36m⯇\u{001B}[0m" : "⯇") : "⯇"
		let RArrow = !isLast ? (isFocused ? "\u{001B}[36m⯈\u{001B}[0m" : "⯈") : "⯈"
		
		// Thought about adding a preview for the next and previous item.. but it takes up a lot of space.
//		let LItem = !isFirst ? "\(options[selectionIdx - 1].description) ": "\u{001B}[90m[begin]\u{001B}[0m "
//		let RItem = !isLast ? " \(options[selectionIdx + 1].description)" : " \u{001B}[90m[end]\u{001B}[0m"
		
		return "\(LArrow) \(formattedSelected) \(RArrow) [\(selectionIdx + 1)/\(options.count)]"
	}
}
