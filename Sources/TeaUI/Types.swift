//
//  Types.swift
//  TeaUI
//
//  Created by Kai Driessen on 2025-08-06.
//

import Foundation

/// Errors concerning failure in managing the terminal.
enum TerminalError: Error {
	case notATerminal
	case failedToGetTerminalSetting
	case failedToSetTerminalSetting
	case notInRawMode
}


/// A command returned from a Model of some kind, asking its parent (or the ``TUI`` itself) to do something.
public protocol Command: Sendable {}


/// A command concerning the TUI.
public enum TUICommand: Command {
	/// Ends the TUI, restoring the terminal and finishing the loop.
	case exit
	/// Ends the TUI and prints a string after exiting raw mode.
	case exitWith(String)
	/// Merges the provided ``AsyncStream`` with the TUI's other streams, allowing you to send ``Event``s back into the ``TUI``, causing it to update.
	case subscribeTo(AsyncStream<Event>)
}

/// A command returned by a ``FocusableModel`` requesting its parent to adjust its focus.
/// - Note: Currently unused.
public enum FocusCommand: Command {
	/// Requests the parent to focus on the next managed item.
	case next
	/// Requests the parent to focus on the previous managed item.
	case previous
	/// Requests the parent to remove focus from this model.
	case blurMe
}


/// An event. Events represent a meaningful change that tells the ``TUI`` to update.
public protocol Event: Sendable {}


/// An event representing a keypress
public enum KeyPress: Event, CustomStringConvertible, Comparable {
	case escape
	case delete
	case forwardDelete
	case pageUp
	case pageDown
	case tab
	case `return` /// Also called the "enter" key.
	case end
	case home
	case fn
	case clear
	case up /// The up arrow key.
	case down /// The down arrow key.
	case left /// The left arrow key.
	case right /// The right arrow key.
//	case numpad(Int) /// A number from the numpad.
//	case number(Int) /// A number from the keyboard.
	case space
	case ascii(Character) /// An ascii character in the range 32 to 126, ignoring cases already covered like space.
	case f1
	case f2
	case f3
	case f4
	case f5
	case f6
	case f7
	case f8
	case f9
	case f10
	case f11
	case f12
	case eject
	
	public var description: String {
		switch self {
			case .escape: "esc"
			case .delete: "del"
			case .forwardDelete: "fdel"
			case .pageUp: "pgup"
			case .pageDown: "pgdwn"
			case .tab: "tab"
			case .return: "ret"
			case .end: "end"
			case .home: "home"
			case .fn: "fn"
			case .clear: "clr"
			case .up: "↑"
			case .down: "↓"
			case .left: "←"
			case .right: "→"
//			case .numpad(let num): String(num)
//			case .number(let num): String(num)
			case .space: "␣"
			case .ascii(let char): String(char)
			case .f1: "f1"
			case .f2: "f2"
			case .f3: "f3"
			case .f4: "f4"
			case .f5: "f5"
			case .f6: "f6"
			case .f7: "f7"
			case .f8: "f8"
			case .f9: "f9"
			case .f10: "f10"
			case .f11: "f11"
			case .f12: "f12"
			case .eject: "eject"
		}
	}
}

