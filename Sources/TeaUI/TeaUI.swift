//
//  TeaUI.swift
//  TeaUI
//
//  Created by Kai Driessen on 2025-08-04.
//


import Foundation
import Combine
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif


public actor TUI {
	/// A stream that can be passed to subprocesses so they can update the view when they make a meaningful change.
	private let (taskStream, taskContinuation) = AsyncStream<Event>.makeStream()
	
	/// A stream that waits for keypresses.
	private let keyStream = AsyncStream<KeyPress> { continuation in
		// Author: Claude AI
		let keyboardListener = Task {
			let keyListener = InputReader()
			
			while !Task.isCancelled {
				if let keyPress = keyListener.getKeyPress() {
					continuation.yield(keyPress)
				}
				try? await Task.sleep(nanoseconds: 1_000_000)
			}
		}
	}
	
	// Author (This variable): Claude AI
	/// Joind streams from subprocesses, keyboard input, and other such updates.
	lazy var eventStream = AsyncStream<Event> { continuation in
		Task {
			await withTaskGroup(of: Void.self) { group in
				group.addTask { [weak self] in
					guard let self else { return }
					
					defer { continuation.finish() }
					for await key in self.keyStream {
						continuation.yield(key)
					}
				}
				
				group.addTask { [weak self] in
					guard let self else { return }
					
					defer { continuation.finish() }
					for await event in self.taskStream {
						continuation.yield(event)
					}
				}
			}
		}
	}
	
	/// Current model.
	private var model: any Model
	
	/// Subprocesses.
	private var eventListeners = [Task<Void, Never>]()
	
	/// A static variable set the first time any TUI sets up the terminal. Static so that the crash handler can safely use it.
	public static private(set) var originalTerminal: termios?
	
	public init(initialModel: any Model) {
		model = initialModel
	}
	
	/// Sets up the terminal for a TUI by enabling raw mode, entering an alternative buffer, and setting other flags that are useful for a TUI.
	func prepareTerminal() throws {
		guard TUI.originalTerminal == nil else {
			// terminal already prepared. Do nothing
			return
		}
		
		
		var originalTerm = termios()
		guard isatty(STDIN_FILENO) != 0 else { // ensure that we're actually running in a terminal
			throw TerminalError.notATerminal
		}

		guard tcgetattr(STDIN_FILENO, &originalTerm) >= 0 else { // check that the terminal could be fetched properly
			throw TerminalError.failedToGetTerminalSetting
		}


		var rawTerm = originalTerm
		// clear unwanted flags
		rawTerm.c_iflag &= ~(UInt(BRKINT) | UInt(ICRNL) | UInt(INPCK) | UInt(ISTRIP) | UInt(IXON)) // input mode flags
		rawTerm.c_lflag &= ~(UInt(ECHO) | UInt(ICANON) | UInt(IEXTEN) | UInt(ISIG)) // local mode flag
		rawTerm.c_oflag &= ~(UInt(OPOST)) // output mode flags
		// set wanted flags
		rawTerm.c_cflag |= UInt(CS8) // set character size to 8 bytes
		rawTerm.c_cc.16 = 0 // min number of bytes to read. 0 mean return immidiatly when data is available (non-blocking)
		rawTerm.c_cc.17 = 1 // timeout for read() (1ms)

		guard tcsetattr(STDIN_FILENO, TCSAFLUSH, &rawTerm) >= 0 else {
			throw TerminalError.failedToSetTerminalSetting
		}
		
		TUI.originalTerminal = originalTerm
		
		// set up crash handlers
		for sig in [SIGINT, SIGHUP, SIGABRT, SIGTRAP, SIGQUIT, SIGSEGV] {
			signal(sig) { sig in
				crashHandler(signum: sig)
				// I would so love to have the crash handlers here or in this class rather than a seperate function...
				// ...but I just can't seem to pass the original into the closure safely.
			}
		}
		
		TUI.enterAltBuffer()
		
		print("\u{001B}[?25l", terminator: "") // hide cursor
		// no need to clear the screen, as every rendering pass does that already
	}
	
	
	/// I do not need to document this.
	static func enterAltBuffer() {
		print("\u{1b}[?1049h", terminator: "")
	}
	
	
	/// I do not need to document this.
	static func exitAltBuffer() {
		print("\u{1b}[?1049l", terminator: "") // exit alternative buffer
		print("\u{001B}[?25h", terminator: "") // show cursor
	}
	
	
	/// Restores the terminal to its default state by exiting the alternative buffer, and pushing flags via tcsetattr.
	private func restoreTerminal() {
		TUI.exitAltBuffer()

		guard var mutableOrigionalTerminal = TUI.originalTerminal else {
			return
		}
		
		tcsetattr(STDIN_FILENO, TCSAFLUSH, &mutableOrigionalTerminal)
	}
	
	
	/// Renders the model by printing its ``Model/body``.
	private func render(_ model: any Model) {
		print("\u{1b}[2J\u{1B}[H\u{1B}[0m", terminator: "") // clear screen, move cursor to Home (1, 1), and reset ANSI formatting
		let parsedBody = model.body.replacingOccurrences(of: "\n", with: "\n\r") // convenience: you don't have to manually add the return (\r) to your Model's body.
		print(parsedBody, terminator: "\n\r") // render the model's body!
	}
	
	
	/// Enters the update-render-wait loop, running until the topmost model returns ``TUICommand/exit`` or ``TUICommand/exitWith(_:)`` as its ``TUICommand``.
	public func run() async throws {
		try prepareTerminal()
		
		var exitStr = ""
		
		render(model) // initial render
		mainloop: for await event in eventStream {
			let command: Command?
			(model, command) = model.update(event)
			render(model)
			
			if let command {
				switch command {
					case let command as TUICommand: switch command {
						case .exit:
							break mainloop
						case .exitWith(let str):
							exitStr = str
							break mainloop
						case .subscribeTo(let stream):
							let task = Task {
								for await response in stream {
									taskContinuation.yield(response)
								}
							}
							eventListeners.append(task)
					}
					default: break
				}
			}
		}
		
		for task in eventListeners {
			task.cancel()
		}
		
		restoreTerminal()
		
		print(exitStr)
	}
}

