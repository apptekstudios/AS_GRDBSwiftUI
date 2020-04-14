// AS_GRDBSwiftUI. Created by Apptek Studios 2020

import Combine
import Foundation
import GRDB

/// An observable object that holds a `MutablePersistableRecord` and allows mutation + updating the database row
@dynamicMemberLookup
public class GRDBPersistableRecord<Value: MutablePersistableRecord>: ObservableObject
{
	let database: DatabaseWriter?

	public var value: Value
	{
		get { _value }
		set {
			_value = newValue
			autosavePublisher?.send()
		}
	}
	
	private var _value: Value {
		willSet
		{
			objectWillChange.send()
		}
	}

	/// Call this function to manually save any changes to the record to the database
	public func commitChanges() throws
	{
		try database?.write {
			do
			{
				try value.update($0)
			}
			catch PersistenceError.recordNotFound {
				try _value.insert($0)
			}
		}
	}

	private let autosavePublisher: PassthroughSubject<Void, Never>?
	private var autosaveSubscription: AnyCancellable?

	/// Initialise a GRDB mutable record with a value
	/// - parameter database: The database to save any changes to.
	/// - parameter value: The initial value
	/// - parameter autoSave: Whether to automatically commit any changes to the database. Default = true
	public init(database: DatabaseWriter, value: Value, autoSave: Bool = true)
	{
		self.database = database
		self._value = value

		if autoSave
		{
			autosavePublisher = PassthroughSubject()
			autosaveSubscription = autosavePublisher?
				.throttle(for: 0.1, scheduler: RunLoop.main, latest: true)
				.sink { [weak self] in
					do
					{
						try self?.commitChanges()
					}
					catch
					{
						// Ignoring errors for autosave
					}
				}
		}
		else
		{
			autosavePublisher = nil
		}
	}

	private init(placeholderValue: Value)
	{
		database = nil
		_value = placeholderValue
		autosavePublisher = nil
	}

	public static func placeholder(_ value: Value) -> GRDBPersistableRecord
	{
		GRDBPersistableRecord(placeholderValue: value)
	}

	/// Allows for directly accessing/editing variables in the stored value
	public subscript<T>(dynamicMember keyPath: WritableKeyPath<Value, T>) -> T
	{
		get { value[keyPath: keyPath] }
		set { value[keyPath: keyPath] = newValue }
	}
}
