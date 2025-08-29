//
//  Container.swift
//  TeaUI
//
//  Created by Kai Driessen on 2025-08-18.
//

/// An item to be rendered by a ``Container``
public enum ContainerItem {
	/// A line to display.
	case line(String = "")
	/// A section in the container.
	case section(String? = nil)
	/// Multiple items that will be treated as individual lines. Useful for running logic.
	indirect case multiple([ContainerItem])
}


/// A helpful little object that make rendering text in neat little boxes much easier.
public struct Container: CustomStringConvertible {
	let contents: [ContainerItem]
	let width: Int
	let title: String?
	let footer: String?
	
	private let regex = try! Regex(#"\u{001B}\[[0-9;]*[A-Za-z]"#)
	
	/// Creates a container that lets you easily group items together in a string.
	/// - Note: Always close ansi escape sequences in your contents, as the container will not do it for you.
	/// - Parameters:
	///   - width: The width in characters of this container. Setting this too small will cause wrapping issues
	///   - contents: The contents of this container.
	///   - title: An optional title to display.
	///   - footer: An optional footer to display.
	/// - Warning: Width may not be less than 2. A precondition will halt execution if you do this.
	public init(width: Int, contents: [ContainerItem], title: String? = nil, footer: String? = nil) {
		precondition(width >= 2)
		
		self.width = width
		self.contents = contents
		self.title = title
		self.footer = footer
	}
	
	// TODO: ideally, a custom truncator/padder should be made instead of .padding(), since padding doesn't account for 0-width characters like ansi codes. What I have now can be considered a hack.
	
	/// Gets the number of 0-width characters in the provided string, like the characters that are part of an ansii colour code.
	/// - Note: Currently only looks for ansi escapes, like "_(esc)_[31m".
	func countInvisibles(of string: String) -> Int {
		return string.matches(of: regex).reduce(0) {
			$0 + $1.0.count
		}
	}
	
	/// Collapses the provided ``ContainerItem``s by appending them to the provided variable.
	/// The only real reason this is a function as opposed to logic within ``description`` is so that it can recursivly collapse ``ContainerItem/multiple(_:)``.
	/// - Parameters:
	///   - items: Items to resolve.
	///   - body: Place to put the resolved items.
	func resolve(_ items: [ContainerItem], into body: inout [String]) {
		for item in items {
			switch item {
				case .line(let line):
					
					// notice the use of countInvisibles(of:) to counteract the fact that the number of characters in the string may be greater than the number of characters actually shown in the terminal.
					body.append("│ " + (line).padding(toLength: width - 3 + countInvisibles(of: line), withPad: " ", startingAt: 0) + "│")
				case .section(let label):
					if let label {
						body.append("├─┤ " + label.appending(" ├").padding(toLength: width - 5 + countInvisibles(of: label), withPad: "─", startingAt: 0) + "┤")
					} else {
						body.append("├" + String(repeating: "─", count: width - 2) + "┤")
					}
				case .multiple(let moreItems):
					resolve(moreItems, into: &body)
			}
		}
	}
	
	
	public var description: String {
		var body = [String]()
		
		if let title {
			// again, using countInvisibles(of:) to counteract 0-width characters like those part of an ansi escape code
			// ideally, a custom truncator/padder should be written.
			body.append("┌─┤ " + title.appending(" ├").padding(toLength: width - 5 + countInvisibles(of: title), withPad: "─", startingAt: 0) + "┐")
		} else {
			body.append("┌" + String(repeating: "─", count: width - 2) + "┐")
		}
		
		resolve(contents, into: &body)
		
		if let footer {
			body.append("└─┤ " + footer.appending(" ├").padding(toLength: width - 5 + countInvisibles(of: footer), withPad: "─", startingAt: 0) + "┘")
		} else {
			body.append("└" + String(repeating: "─", count: width - 2) + "┘")
		}
		
		return body.joined(separator: "\n")
	}
}
