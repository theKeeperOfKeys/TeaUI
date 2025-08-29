//
//  CrashHandler.swift
//  TeaUI
//
//  Created by Kai Driessen on 2025-08-07.
//

import Foundation

func crashHandler(signum: Int32) -> Void {
	TUI.exitAltBuffer()
	
	if var mutableOriginalTerminal = TUI.originalTerminal {
		tcsetattr(STDIN_FILENO, TCSAFLUSH, &mutableOriginalTerminal)
	}
	
	fputs("\n\rPROGRAM PANIC.\n\r", stderr)
	fputs("(terminal restored)\n\r", stderr)
	fflush(stderr)
	
	signal(signum, SIG_DFL) // restore signal disposition to prevent infinite recursion
	raise(signum) // raise the error
}

