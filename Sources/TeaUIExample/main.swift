//
//  main.swift
//  TeaUI
//
//  Created by Kai Driessen on 2025-08-25.
//

import Foundation
import TeaUI

let app = TUI(initialModel: MainModel())
do {
	print("\u{1B}[8;40;100t") // resize the terminal to 100 by 40 if supported
	try await app.run()
} catch {
	print("Crashed!")
}
