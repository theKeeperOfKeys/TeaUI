//
//  BackgroundTasks.swift
//  TeaUI
//
//  Created by Kai Driessen on 2025-08-26.
//

import Foundation
import TeaUI

enum BackgroundTasksCommand: Command {
	case startProcessing
	case cancel
}

enum BackgroundTaskEvent: Event {
	case notification(String)
	case progressed(Float)
	case done
	case failed(String)
}

enum TaskStatus: CustomStringConvertible {
	case notStarted
	case inProgress(Float)
	case done
	case failed(String)
	
	var description: String {
		switch self {
			case .notStarted:
				"Not started"
			case .inProgress(let percent):
				"In progress... (\(percent)%)"
			case .done:
				"Done"
			case .failed(let reason):
				"Failed. Reason: \(reason)"
		}
	}
}


// When you write your function to preform the background job, make sure that you don't go overboard with the events you send to the TUI.
// Every event you push back to the TUI makes it preform its whole "frame" loop, and if you have complex models, this can get out of hand quickly.
func doJob(withContinuation continuation: AsyncStream<any Event>.Continuation) {
	do {
		continuation.yield(BackgroundTaskEvent.progressed(0))
		sleep(1)
		try Task.checkCancellation()
		continuation.yield(BackgroundTaskEvent.notification("Doing the thing..."))
		continuation.yield(BackgroundTaskEvent.progressed(20))
		
		sleep(1)
		try Task.checkCancellation()
		continuation.yield(BackgroundTaskEvent.progressed(40))
		continuation.yield(BackgroundTaskEvent.notification("50% chance to fail! Fingers crossed."))
		
		sleep(1)
		try Task.checkCancellation()
		if Bool.random() {
			continuation.yield(BackgroundTaskEvent.failed("The process encountered bad luck and failed."))
			continuation.finish()
			return
		}
		continuation.yield(BackgroundTaskEvent.notification("No failure! We got lucky."))
		continuation.yield(BackgroundTaskEvent.progressed(60))
		
		sleep(1)
		try Task.checkCancellation()
		continuation.yield(BackgroundTaskEvent.progressed(80))
		continuation.yield(BackgroundTaskEvent.notification("Almost done..."))
		
		sleep(1)
		try Task.checkCancellation()
		continuation.yield(BackgroundTaskEvent.progressed(100))
		continuation.yield(BackgroundTaskEvent.notification("Done!"))
		continuation.yield(BackgroundTaskEvent.done)
		continuation.finish()
	} catch is CancellationError {
		continuation.yield(BackgroundTaskEvent.failed("Cancelled"))
		continuation.finish()
	} catch {
		continuation.yield(BackgroundTaskEvent.failed("Error Occurred"))
		continuation.finish()
	}
}


struct BackgroundTasksModel: FocusManager {
	var startButton = Button(label: "Start", pressCommand: BackgroundTasksCommand.startProcessing)
	var cancelButton = Button(label: "Cancel", pressCommand: BackgroundTasksCommand.cancel)
	
	var feedback: [String] = []
	var status: TaskStatus = .notStarted
	
	static let managedModels: [any PartialKeyPath<BackgroundTasksModel> & Sendable] = [
		\Self.startButton,
		\Self.cancelButton,
	]
	
	var focusIndex = 0
	var isFocused = true
	
	var backgroundTask: Task<Void, Never>?
	
	
	init() {
		changeFocus(of: focusIndex, to: true)
	}
	
	
	func update(_ event: any Event) -> (any Model, Command?) {
		var newModel = self
		
		let (command, eventWasConsumed) = newModel.updateFocused(event)
		
		if let bgCommand = command as? BackgroundTasksCommand { // the buttons want something to happen! Lets see what it is...
			switch bgCommand {
				case .startProcessing:
					if backgroundTask == nil {
						let stream = AsyncStream<any Event> { continuation in
							newModel.backgroundTask = Task {
								doJob(withContinuation: continuation)
							}
						}
						newModel.status = .inProgress(0)
						newModel.feedback = []
						return (newModel, TUICommand.subscribeTo(stream))
					}
				case .cancel:
					newModel.backgroundTask?.cancel()
					newModel.backgroundTask = nil
			}
			return (newModel, nil) // early exits are vital in complex models.
		}
		
		// with buttons in the mix, you should only check for event consumption after you've handled the buttons' actions.
		if eventWasConsumed {
			return (newModel, nil)
		}
		
		
		switch event {
			case let event as BackgroundTaskEvent: // the background task sent an event!
				switch event {
					case .notification(let msg):
						newModel.feedback.append(msg)
					case .progressed(let newProgress):
						newModel.status = .inProgress(newProgress)
					case .done:
						newModel.status = .done
						newModel.backgroundTask = nil
					case .failed(let message):
						newModel.status = .failed(message)
						newModel.backgroundTask = nil
				}
				return (newModel, nil)
				
			case let event as KeyPress: // oh, just a boring keypress
				switch event {
					case .up:
						newModel.focusPrev()
					case .down:
						newModel.focusNext()
					case .escape:
						// return to the main menu
						// remember to cancel tasks!
						backgroundTask?.cancel()
						return (MainModel(), nil)
					default: break
				}
				
			default: break
		}
			
		return (newModel, nil)
	}
	
	var body: String {
		return Container(
			width: 80,
			contents: [
				.line(),
				.line("Status: \(status)"),
				.line(),
				.section("Feedback"),
				.line(),
				.multiple(
					feedback.map { ContainerItem.line($0) }
				),
				.line(),
				.section(),
				.line(),
				.line(startButton.body),
				.line(cancelButton.body),
				.line(),
			],
			title: "Background Work Demo",
			footer: "[\(Clr.cyan)↑\(Fmt.reset)][\(Clr.cyan)↓\(Fmt.reset)] \(Clr.cyan)navigate\(Fmt.reset) │ [\(Clr.yellow)esc\(Fmt.reset)] \(Clr.yellow)return to main menu\(Fmt.reset)"
		).description
	}
}
