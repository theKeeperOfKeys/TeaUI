//
//  MainModel.swift
//  TeaUI
//
//  Created by Kai Driessen on 2025-08-25.
//

import Foundation
import TeaUI

struct MainModel: Model {
	var cursorIdx = 0
	
	let options = [
		"Terminal Formatting",
		"Premade Components & Focus Management",
		"Background Tasks",
	]
	
	init() {}
	
	func update(_ event: any Event) -> (any Model, Command?) {
		switch event {
			case let keyPress as KeyPress:
				var newModel = self
				switch keyPress {
					case .up:
						// decrement with wraparound
						newModel.cursorIdx = (cursorIdx - 1 + options.count) % options.count
					case .down:
						// increment with wraparound
						newModel.cursorIdx = (cursorIdx + 1) % options.count
					case .return:
						switch cursorIdx {
							// there are many different ways to implement this, but hard-coding is often the simplest.
							// ...just don't forget to account for all cases when you add more views!
							case 0:
								return (TerminalFormattingModel(), nil)
							case 1:
								return (PremadesModel(), nil)
							case 2:
								return (BackgroundTasksModel(), nil)
							default:
								fatalError("cursor index out of bounds")
						}
					case .escape:
						// quit the program
						return (self, TUICommand.exitWith("\(Clr.blue)Happy Coding!\(Fmt.reset)"))
						
					default: break
				}
				return (newModel, nil)
				
			default: break
		}
		
		
		return (self, nil)
	}
	
	
	var body: String {
		// prepare all the navigation options
		let navigationOptions = options.indices.map { index in
			let item = options[index]
			let focus = index == cursorIdx ? ("\(Clr.intenseCyan)[\(Fmt.reset) ", " \(Clr.intenseCyan)]\(Fmt.reset)") : ("  ", "  ")
			return ContainerItem.line(focus.0 + item + focus.1)
		}
		
		// Check TerminalFormatting.swift to learn how to use the Container.
		// Or better yet, just read Container.swift! Its really quite simple.
		let container = Container(
			width: 80, // 80 is the default width for macOS terminals, so this is a safe size to use
			contents: [
				.line(),
				.line("This is an example project to help you get familiar with \(Clr.red)TeaUI\(Fmt.reset)."),
				.line("Below are some screens to showcase all the features."),
				.line(),
				.section("Choose an option: "),
				.line(),
				.multiple(navigationOptions),
				.line(),
				.section(),
				.line("Most parts of the API are documented."),
				.line("If you find missing documentation, please add it! \(Clr.red)<3\(Fmt.reset)"),
			],
			title: "\(Clr.green)Swift TeaUI Example Project\(Fmt.reset)",
			footer: "[\(Clr.cyan)↑\(Fmt.reset)][\(Clr.cyan)↓\(Fmt.reset)] \(Clr.cyan)navigate\(Fmt.reset) │ [\(Clr.green)ret\(Fmt.reset)] \(Clr.green)select\(Fmt.reset) │ [\(Clr.yellow)esc\(Fmt.reset)] \(Clr.yellow)quit\(Fmt.reset)"
		)
		
		return """
		\u{1B}[8;40;100t\(Clr.grey)example project v1\(Fmt.reset)

		\(container)

		\(Clr.grey)package v0.1.0\(Fmt.reset)
		"""
	}
}
