//
//  InputReader.swift
//  TeaUI
//
//  Created by Claude AI on 2025-08-06.
//

import Foundation


class InputReader {
	// Author: ClaudeAI
	func getKeyPress() -> KeyPress? {
		guard isDataAvailable(timeoutMs: 0) else {
			return nil // No data available, return immediatly
		}
		if let char = readChar() {
			return parseChar(char)
		}
		return nil
	}
	
	
	// Author: ClaudeAI
	private func readChar() -> UInt8? {
		var char: UInt8 = 0
		let result = read(STDIN_FILENO, &char, 1)
		return result == 1 ? char : nil // 1 == sucess.
	}

	
	// Author: ClaudeAI
	private func parseChar(_ char: UInt8) -> KeyPress? {
		switch char {
			case 8: // backspace on many terminals
				return .delete
			case 9:
				return .tab
			case 10: // Line Feed (sometimes used for enter)
				return .return
			case 13: // Carrage return
				return .return
			case 27:
				return parseEscapeSequence()
			
			case 32:
				return .space
			
			case 32...126: // Valid ASCII
				return .ascii(Character(UnicodeScalar(char)))
			
			case 127:
				return .delete
			
			default:
				return nil
		}
	}
	
	
	// Author: ClaudeAI
	private func parseEscapeSequence() -> KeyPress {
		// Check if more data is available within 100ms
		 guard isDataAvailable(timeoutMs: 100) else {
			 return .escape // No more data, just ESC
		 }
		 
		 guard let nextChar = readChar() else {
			 return .escape
		 }
		 
		 if nextChar == 91 { // '['
			 guard isDataAvailable(timeoutMs: 50), let thirdChar = readChar() else {
				 return .escape
			 }
			 
			 switch thirdChar {
			 case 65: return .up
			 case 66: return .down
			 case 67: return .right
			 case 68: return .left
			 default: return .escape
			 }
		 }
		
		 return .escape
	}
	
	
	// Author: ClaudeAI
	private func isDataAvailable(timeoutMs: Int) -> Bool {
		var pollfd = pollfd()
		pollfd.fd = STDIN_FILENO
		pollfd.events = Int16(POLLIN)
		
		let result = poll(&pollfd, 1, Int32(timeoutMs))
		return result > 0 && (pollfd.revents & Int16(POLLIN)) != 0
	}
}

