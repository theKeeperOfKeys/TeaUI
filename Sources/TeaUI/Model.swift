//
//  Model.swift
//  TeaUI
//
//  Created by Kai Driessen on 2025-08-14.
//

import Foundation

/// A model representing the state of your TUI or a part thereof.
///
/// Every "frame" of the ``TUI``'s loop consists of three steps:
/// - ``Model/update(_:)`` is called, letting your model know that a change has occurred.
/// The model then returns an updated self, or a totally different model, as well as an optional command for the TUI to handle later.
/// - The model is rendered using its ``Model/body``.
/// - The TUI handles the command returned from the `update` step above, if any.
///
/// While you can use a Model to represent the state of your entire app, it is often better to split it up into multiple parts.
/// Models can easily act as submodels by simply existing as part of a parent model, getting updated it the parent's ``Model/update(_:)``, and being added to the parent's ``Model/body``.
public protocol Model: Sendable, CustomStringConvertible {
	/// Update is called when an event is received. Use it to inspect messages and, in response, update the model and send an optional command.
	func update(_ event: Event) -> (any Model, Command?)
	/// The textual representation of this model. The body is read after every update.
	var body: String { get }
}
public extension Model {
	var description: String { body }
}


// TODO: consider adding StaticModel, which is just Model without the ability to change to a completely different model (which will remove the need for a runtime check in KeyPathActionDelegate).
// Something like
//public protocol StaticModel: Sendable, CustomStringConvertible {
//	/// Updates the model based on the given event. Returns an updated self, along with an optional command.
//	func update(_ event: Event) -> (Self, Command?)


/// A model with extra properties to allow it to be focused.
public protocol FocusableModel: Model {
	/// The focused state of this model. You do not normally need to check the focus state inside ``Model/update(_:)``, as that should not be called unless focused.
	var isFocused: Bool { get set }
	
	// Used by KeyPathActionDelegate.
	mutating func setFocus(to newFocus: Bool)
}
public extension FocusableModel {
	mutating func setFocus(to newFocus: Bool) { isFocused = newFocus }
}


public protocol FocusManager: FocusableModel {
	/// Models managed by this object. The order of the items dictates the order in which they will be focused.
	/// - Warning: Ensure that only keypaths to ``FocusableModel``s or ``FocusManager``s are present in this array.
	/// In a debug build, you will get a runtime error if this is the case. In release builds, focus-adjusting functions will return early, possibly leaving your app in an undesired state.
	static var managedModels: [PartialKeyPath<Self> & Sendable] { get }
	/// The current index of focus. Dictates which item currently has focus.
	/// If you need multiple items to have focus at once, create a ``FocusableModel`` containing said items, and implement custom logic yourself.
	var focusIndex: Int { get set }
//	var focusedModel: (any Model)? { get }
	
	init()
	
	/// Initializes this model, allowing you to set the initial state of focus.
	/// You probably want to set the focus to true when you initialize a new model to be returned as the root model for your ``TUI``.
	///
	/// This initializer has a default implementation and does not need to be included in the majority of cases.
	init(initialFocus: Bool)
}
extension FocusManager {
	// I've yet to need to get the currently focused model. If you want this functionality, please add and test this!
//	var focusedModel: (any Model)? {
//		return self.isFocused ? self : Self.managedModels.lazy.map { managedKeyPath in
//			let focused = self[keyPath: managedKeyPath] as? any Model
//			switch focused {
//				case nil:
//					return nil
//				case let focused as any FocusManager:
//					return focused.focusedModel // needs testing
//				default:
//					return focused
//			}
//		}[focusIndex]
//	}	
	/// Gets the ``KeyPathActionDelegate`` of the currently focused item managed in ``FocusManager/managedModels``.
	/// In debug builds, trying to access an incompatible type inside ``FocusManager/managedModels`` will raise a runtime error.
	internal var focusedActionDelegate: (any KeyPathActionDelegate<Self>)? {
		let actionPerformer = Self.managedModels[focusIndex] as? any KeyPathActionDelegate<Self>
		
		#if DEBUG
		guard let actionPerformer else {
			fatalError("Illegal Member - Only Models or FocusManagers are allowed to be managed by a FocusManager, but a value of type \(type(of: Self.managedModels[focusIndex])) was included in managedModels.")
		}
		#endif
		
		return actionPerformer
	}
	
	
	public init(initialFocus: Bool) {
		self.init()
		setFocus(to: initialFocus)
	}
	

	/// Changes the focus of a managed item.
	/// - Parameters:
	///   - focusIdx: Index of the item you wish to adjust.
	///   - newVal: The new state of focus.
	public mutating func changeFocus(of focusIdx: Int, to newVal: Bool) {
		guard !Self.managedModels.isEmpty else {
			return // nothing to set
		}
		
		focusedActionDelegate?.setFocus(to: newVal, in: &self)
	}

	
	/// Gives focus to the next item managed in ``FocusManager/managedModels``.
	/// - Warning: In debug builds, trying to give focus to an incompatible type inside ``FocusManager/managedModels`` will raise a runtime error.
	/// In release builds, it will simply skip that object, potentially leaving your app in an undesired state.
	public mutating func focusNext() {
		self.changeFocus(of: focusIndex, to: false)
		// increment with wraparound
		focusIndex = (focusIndex + 1) % Self.managedModels.count
		self.changeFocus(of: focusIndex, to: true)
	}

	
	/// Gives focus to the previous item managed in ``FocusManager/managedModels``.
	/// - Warning: In debug builds, trying to give focus to an incompatible type inside ``FocusManager/managedModels`` will raise a runtime error.
	/// In release builds, it will simply skip that object, potentially leaving your app in an undesired state.
	public mutating func focusPrev() {
		self.changeFocus(of: focusIndex, to: false)
		// decrement with wraparound
		focusIndex = (focusIndex - 1 + Self.managedModels.count) % Self.managedModels.count
		self.changeFocus(of: focusIndex, to: true)
	}
	
	
	/// Overwriting ``Focusable``'s default implementation.
	/// Includes logic to automatically change focus of the focused submodel when this model gains or loses focus.
	public mutating func setFocus(to newFocus: Bool) {
		isFocused = newFocus
		if newFocus == true {
			// when gaining focus, set focus of child item
			changeFocus(of: focusIndex, to: true)
		} else {
			// when loosing focus, reset focused child item
			changeFocus(of: focusIndex, to: false)
		}
	}
	
	
	/// Updates the focused model, and returns its command.
	/// - Parameter event: the event
	/// - Returns: The returned command, if any, along with a boolean indicating if the event was consumed, or if a parent model should handle it.
	/// - Warning: Metamorphosis is not allowed. If the focused model attempts to change types, a runtime error will instead be raised.
	/// - Note: At this time, didConsumeEvent is always false. Its functionality still needs to be added.
	public mutating func updateFocused(_ event: Event) -> (Command?, didConsumeEvent: Bool) {
		return (focusedActionDelegate?.update(event, in: &self), false)
	}
}


/// A delegate used to update the focus of managed items inside a ``FocusManager`` in a type safe way.
protocol KeyPathActionDelegate<Root> {
	associatedtype Root
	
	func setFocus(to newFocus: Bool, in root: inout Root)
	func update(_ event: Event, in root: inout Root) -> Command?
}


extension WritableKeyPath: KeyPathActionDelegate where Value: FocusableModel {
	func setFocus(to newFocus: Bool, in root: inout Root) {
		root[keyPath: self].setFocus(to: newFocus)
	}
	
	
	func update(_ event: Event, in root: inout Root) -> Command? {
		let (updatedForm, command) = root[keyPath: self].update(event)
		
		guard let finalForm = updatedForm as? Value else {
			#if DEBUG
			fatalError("Metamorphosis Prohibited - Model managed by a FocusManager is not allowed to transform into a different Model.")
			#else
			return nil
			#endif
		}
		
		root[keyPath: self] = finalForm
		
		return command
	}
}
