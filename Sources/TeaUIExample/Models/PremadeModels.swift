//
//  PremadeModels.swift
//  TeaUI
//
//  Created by Kai Driessen on 2025-08-25.
//

import Foundation
import TeaUI

// create a command that our buttons will be returning when pressed.
enum PremadeModelsButtonCommand: Command {
	case number1
	case number2
}

// When you conform your model to FocusManger, it will be provided with some useful functions to help manage focus.
struct PremadesModel: FocusManager {
	// Spinners are useful for inputting numbers
	var spinner1 = Spinner(value: 5, step: 1, range: 0...100)
	var spinner2 = Spinner(value: 0, step: 5, range: -50...50)
	
	// A Text Field. Use to enter text.
	var textField1 = TextField(label: "Text Field", placeholder: "Placeholder Text", maxChars: 64)
	var textField2 = TextField(label: "Small Text Field", placeholder: "max 3 chars", maxChars: 3)
	
	// A selector is a sort of inline dropdown menu.
	var selector = Selector(options: [
		"\(Clr.darkGrey)choose...\(Fmt.reset)", // You can use colors inside the options - just make sure you close the tag with Fmt.reset.
		"Item A",
		"Item B",
		"\(Clr.blue)Item C\(Fmt.reset)",
		"Item D"
	])
	
	// Ah, the trusty toggle. Perfect for choosing between one or more related options.
	var checkBox1 = Toggle()
	var checkBox2 = Toggle()
	
	// Ah, the spectacular switch. No UI is complete without one.
	var switch1 = Toggle(style: .switch)
	
	var button1 = Button(label: "Activate Mode 1", pressCommand: PremadeModelsButtonCommand.number1)
	var button2 = Button(label: "Activate Mode 2", pressCommand: PremadeModelsButtonCommand.number2)
	
	// You can easily create your own FocusableModels!
	
	
	
	// This array tells FocusManager which models you want to manage. Order them in the order they should be focused on.
	// Make sure it only points to FocusableModels or FocusManagers, or else one of two things will happen:
	// - In a debug build, you will get a runtime error.
	// - In a release build, that object will be ignored, (but not skipped) leaving empty gaps in your app's focusable elements.
	// Additionally, you should also ensure that models managed here will never metamorphosize (change into a completely different model) or else:
	// - In a debug build, you'll get another runtime error.
	// - In a release build, that update will be dropped, and the model will remain unchanged.
	// The premade models will never do this, so you only need to worry about that when you make your own ones.
	// Last thing, I promise! You also have to ensure that the models included are mutable (var not let). Else... you guessed it! Runtime error / skip.
	static let managedModels: [any PartialKeyPath<PremadesModel> & Sendable] = [
		\Self.spinner1,
		\Self.spinner2,
		\Self.textField1,
		\Self.textField2,
		\Self.checkBox1,
		\Self.checkBox2,
		\Self.switch1,
		\Self.button1,
		\Self.button2,
		\Self.selector,
	]
	
	// The focusIndex determines which object is currently focused.
	// If you want to support multiple focused objects, or handle focus some other way, you will need to implement that yourself.
	var focusIndex = 0
	
	// isFocused is required by FocusableModels, which a FocusManager is. For the "main", or "root" model, focus doesn't really matter. We set it to true anyway.
	// isFocused is not checked or used by default, and its up to the implementer to decide what a model should do based on it's focus.
	// If your FocusManger is some kind of sub-model, like a panel that manages the focus of its contents, it makes sense to use this.
	var isFocused = true
	
	// Something for the buttons to affect.
	var mode = true
	
	init() {
		// When your view is created, you don't want to have nothing focused, do you?
		// This is a protocol-provided method that does exactly what it says.
		changeFocus(of: focusIndex, to: true)
		// you can use this method to manually handle focus if you want.
	}
		
	func update(_ event: any Event) -> (any Model, Command?) {
		var newModel = self
		
		// This protocol-provided method runs the update function on the focused model (based on the focusIndex) and returns its returned command if any
		// If the submodel handled the event, then you can finish right now.
		// Note that didConsumeEvent is currently always false until I implement it.
		let (command, didConsumeEvent) = newModel.updateFocused(event)
		
		if let buttonCmd = command as? PremadeModelsButtonCommand {
			switch buttonCmd {
				case .number1:
					// button 1 was pressed! Do its job.
					newModel.mode = true
				case .number2:
					// button 2 was pressed!
					newModel.mode = false
			}
		}
		
		if didConsumeEvent {
			return (newModel, nil)
		}
		// Right now, there is no way to run update on multiple managed models ignoring focusIndex (for having multiple focused items that you manage yourself).
		
		
		
		switch event {
			case let keyPress as KeyPress:
				switch keyPress {
					case .up:
						// these are protocol-provided methods that lets you easily increment or decrement the focus.
						// it even wraps around to the last when at the start!
						newModel.focusPrev()
					case .down:
						// very convenient, isn't it? Much simpler than what you'd need in BubbleTea.
						// it even wraps around to the first item when at the end!
						newModel.focusNext()
					case .escape:
						// return to the main view
						return (MainModel(), nil)
						
					default: break
				}
			default: break
		}
		
		return (newModel, nil)
	}
	
	
	var body: String {
		let container = Container(
			width: 80,
			contents: [
				.line(),
				.section("Spinners"),
				.line(),
				.line(spinner1.body),
				.line(spinner2.body),
				.line("[\(Clr.cyan)←\(Fmt.reset)][\(Clr.cyan)→\(Fmt.reset)] \(Clr.cyan)increment\(Fmt.reset) / \(Clr.cyan)decrement\(Fmt.reset)"),
				.line("[\(Clr.cyan)del\(Fmt.reset)] \(Clr.cyan)reset to default\(Fmt.reset)"),
				.line("[\(Clr.cyan)0\(Fmt.reset)...\(Clr.cyan)9\(Fmt.reset)] \(Clr.cyan)set number\(Fmt.reset)"),
				.line("[!] \(Clr.grey)Typing negative numbers is not yet supported.\(Fmt.reset)"),
				.line(),
				.section("Text Fields"),
				.line(),
				.line(textField1.body),
				.line(textField2.body),
				.line("[!] \(Clr.grey)Manipulating the cursor is not yet supported.\(Fmt.reset)"),
//				.line("Press return to sumbit - which will move focus down."),
				// ^ not yet it won't lol
				.line(),
				.section("Buttons & Switches"),
				.line(),
				.line(checkBox1.body + " checkbox 1"),
				.line(checkBox2.body + " checkbox 2"),
				.line(switch1.body + " switch"),
				.line(button1.body),
				.line(button2.body),
				.line(),
				.section("Selector"),
				.line(),
				.line(selector.body),
				.line("This is currently the closest you can get to dropdown."),
				.line("[\(Clr.cyan)←\(Fmt.reset)][\(Clr.cyan)→\(Fmt.reset)] \(Clr.cyan)browse options\(Fmt.reset)"),
				.line("[\(Clr.cyan)del\(Fmt.reset)] \(Clr.cyan)reset to first item\(Fmt.reset)"),
				.line(),
			],
			title: "Premade UI Models Showcase",
			footer: "[\(Clr.cyan)↑\(Fmt.reset)][\(Clr.cyan)↓\(Fmt.reset)] \(Clr.cyan)navigate\(Fmt.reset) │ [\(Clr.yellow)esc\(Fmt.reset)] \(Clr.yellow)back\(Fmt.reset)"
		)
		
		return """
\u{1B}[8;42;100t\(container)
\(Clr.grey)Note that the premade models do not yet support disability. (You cannot disable them)\(Fmt.reset)
\(Fmt.bold)-- Here's how you can use the values of the objects --\(Fmt.reset)
Value of both spinners combined: \(spinner1.value + spinner2.value) 
Characters in Text Field 1: \(textField1.value.count)
Chosen item in selector: \(selector.selected ?? "nil") (index \(selector.selectionIdx))
Average value of checkboxes: \(checkBox1.isChecked && checkBox2.isChecked ? "true" : (checkBox1.isChecked != checkBox2.isChecked ? "trulse" : "false"))
Switch is on: \(switch1.isChecked ? "yep": "nope")
Mode: \(mode ? "\(Clr.green)1" : "\(Clr.magenta)2")\(Fmt.reset) (No effect. Example only. Change with buttons)
"""
	}
}
