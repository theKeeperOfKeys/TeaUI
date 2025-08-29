//
//  TerminalFormatting.swift
//  TeaUI
//
//  Created by Kai Driessen on 2025-08-26.
//

import Foundation
import TeaUI

// Check out PremadeModels.swift to learn how to use the FocusManager API.
struct TerminalFormattingModel: Model {
	func update(_ event: any Event) -> (any Model, Command?) {
		if let keyPress = event as? KeyPress, keyPress == .escape {
			// return to the main menu
			return (MainModel(), nil)
		}
			
		return (self, nil)
	}
	
	
	var body: String {
		let container = Container(
			width: 80,
			contents: [
				.line(), // padding with an empty line is visually pleasing, but takes up precious lines.
				.line("It can hold regular text..."),
				.line("\(Clr.green)...ansi codes...\(Fmt.reset)"),
				.line("...and even emojis🫸😮🫷"),
				.line(),
				.section(),
				.line(),
				.line("Add sections to organize stuff."),
				.line(),
				.section("And give them labels. (\(Clr.blue)With color!\(Fmt.reset))"),
				.line(),
				// the multiple case is good for dynamically added stuff.
				.multiple(["dynamic item A", "dynamic item B", "dynamic item C"].map { ContainerItem.line($0) } ),
				.line(),
			],
			title: "It can have a title.",
			footer: "It can even get a footer."
		)
				
		return """
\(Clr.green)AnsiColour\(Fmt.reset) (aka \(Clr.green)Clr\(Fmt.reset)) is your \(Clr.intenseYellow)best friend\(Fmt.reset) when it comes to making your app look \(Clr.cyan)pretty\(Fmt.reset).
Its just an enum that converts to an equivalent ANSI colour code.
We got \(Clr.blue)regular\(Fmt.reset), \(Clr.intenseBlue)intense\(Fmt.reset), and \(Clr.blue.background)background\(Fmt.reset) flavours!

Alongside that, \(Clr.green)AnsiFormat\(Fmt.reset) (aka \(Clr.green)Fmt\(Fmt.reset)) will let you \(Fmt.bold)easily\(Fmt.reset) add some \(Fmt.blink)extra cool\(Fmt.reset) effects to your app.

\(Fmt.blink)Blink\(Fmt.reset), \(Fmt.rapidBlink) Faster Blink\(Fmt.reset), 
\(Fmt.bold)Bold\(Fmt.reset), \(Fmt.italic)Italic\(Fmt.reset) (where supported), 
\(Fmt.strikethrough)Strikethrough\(Fmt.reset), \(Fmt.underline)Underline\(Fmt.reset),
\(Fmt.invert)Inverted\(Fmt.reset), and \(Fmt.hidden)Hidden\(Fmt.reset) (Hidden).

You can even combine tags, but why stop there? Use them ALL to create the \(Fmt.blink)\(Fmt.underline)\(Fmt.strikethrough)\(Fmt.italic)\(Fmt.invert)\(Fmt.bold)\(Clr.cyan)\(Clr.intenseRed.background)ULTIMATE EYESORE\(Fmt.reset).

🐦‍🔥\(Clr.red)Swift\(Fmt.reset) also has 💰\(Clr.intenseYellow)rich\(Fmt.reset) support for 😉\(Clr.yellow)emojis\(Fmt.reset), making it very easy to add them to your app. 
Go nuts 🥜 and you 🫵 can make 🏗️ your app 📱 truly ✨😂Cringe Tastic🔥⚡️!!!

The \(Clr.blue)Container\(Fmt.reset) is a nifty little thing that creates neat boxes for your app's content.

\(container)

>> Press [\(Clr.yellow)esc\(Fmt.reset)] to go back to the main menu.
"""
	}
}
