//
//  File.swift
//  TeaUI
//
//  Created by Kai Driessen on 2025-08-07.
//

import Foundation

public typealias Clr = AnsiColor
public typealias Fmt = AnsiFmt

/// ANSI color code for terminal coloring.
public enum AnsiColor: Int, CustomStringConvertible, RawRepresentable {
	public var description: String {
		return "\u{001B}[\(self.rawValue)m"
	}
	
	public var str: String {
		self.description
	}
	
	///
	public var background: String {
		// offset by 10 for background color codes
		return "\u{001B}[\(self.rawValue + 10)m"
	}
	
	case black = 30
	case red = 31
	case green = 32
	case yellow = 33
	case blue = 34
	case magenta = 35
	case cyan = 36
	case grey = 37
	
	/// Really "intense grey", but its usually darker than normal grey in most terminals.
	case darkGrey = 90
	case intenseRed = 91
	case intenseGreen = 92
	case intenseYellow = 93
	case intenseBlue = 94
	case intenseMagenta = 95
	case intenseCyan = 96
	case white = 97
}


/// ANSI formatting codes for text styles.
public enum AnsiFmt: Int, CustomStringConvertible, RawRepresentable {
	public var description: String {
		return "\u{001B}[\(self.rawValue)m"
	}
	
	public var str: String {
		self.description
	}
	
	/// Resets all formatting.
	case reset = 0
	/// Marks text as _bold_.
	case bold = 1
	/// Requests text to be _italic_.
	/// - WARNING: Italic text is not supported by all terminals.
	case italic = 3
	/// _Underlines_ the text.
	case underline = 4
	/// Causes the text to _blink_.
	case blink = 5
	/// Causes the text to _blink_ rapidly.
	case rapidBlink = 6
	/// Swaps the foreground color and the background color.
	case invert = 7
	/// I actually don't know what this one does. I'll need to test it.
	case hidden = 8
	/// Marks the text as _strikethrough_.
	case strikethrough = 9
}


public extension String {
	/// Returns itself with an ANSI color code added to the start of the string, and an ANSI reset at the end.
	func colored(_ color: AnsiColor) -> String {
		return color.str + self + "\u{001B}[0m"
	}
	
	/// Adds an ANSI color code to the start of the string, and adds an ANSI reset to the end.
	mutating func color(_ color: AnsiColor) {
		self = self.colored(color)
	}
	
	/// Returns itself with an ANSI formatting code added to the start of the string, and an ANSI reset at the end.
	func styled(_ format: AnsiFmt) -> String {
		return format.str + self + "\u{001B}[0m"
	}
	
	/// Adds an ANSI formatting code to the start of the string, and adds an ANSI reset to the end.
	mutating func style(_ format: AnsiFmt) {
		self = self.styled(format)
	}
}

/// Causes a beep by printing the system bell character (`\u{007}`).
public func beep() {
	print("\u{007}", terminator: "")
}
