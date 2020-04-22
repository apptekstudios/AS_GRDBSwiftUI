// AS_GRDBSwiftUI. Created by Apptek Studios 2020

import Combine
import Foundation
import GRDB
import SwiftUI

@propertyWrapper
public struct GRDBPersistable<Value: MutablePersistableRecord>: DynamicProperty
{
	@ObservedObject
	var store: GRDBWriteableStore<Value, SaveRequest<Value>>

	@Environment(\.grdbDatabaseWriter)
	var databaseWriter

	public init(_ wrappedValue: Value, autoSave: Bool = false)
	{
		store = GRDBWriteableStore(database: nil, value: wrappedValue, writeRequest: SaveRequest(), autoSave: autoSave)
	}

	public var wrappedValue: Value
	{
		get { store.value }
		nonmutating set { store.value = newValue }
	}

	public func commitChanges() throws
	{
		try store.commitChanges()
	}

	public func update()
	{
		store.database = databaseWriter
	}

	public var projectedValue: Binding<Value>
	{
		Binding(
			get: {
				self.store.value
			},
			set: {
				self.store.value = $0
		})
	}
}

@propertyWrapper
public struct GRDBWriteable<Value, WriteRequest: GRDBWriteRequest>: DynamicProperty where WriteRequest.Value == Value
{
	@ObservedObject
	var store: GRDBWriteableStore<Value, WriteRequest>

	@Environment(\.grdbDatabaseWriter)
	var databaseWriter

	public init(_ wrappedValue: Value, autoSave: Bool = false, writeRequest: WriteRequest)
	{
		store = GRDBWriteableStore(database: nil, value: wrappedValue, writeRequest: writeRequest, autoSave: autoSave)
	}

	public var wrappedValue: Value
	{
		get { store.value }
		nonmutating set { store.value = newValue }
	}

	public func commitChanges() throws -> WriteRequest.Result?
	{
		try store.commitChanges()
	}

	public func update()
	{
		store.database = databaseWriter
	}

	public var projectedValue: Binding<Value>
	{
		Binding(
			get: {
				self.store.value
			},
			set: {
				self.store.value = $0
		})
	}
}

internal class GRDBWriteableStore<Value, WriteRequest: GRDBWriteRequest>: ObservableObject where WriteRequest.Value == Value
{
	var database: DatabaseWriter?
	var writeRequest: WriteRequest

	var value: Value
	{
		get { _value }
		set
		{
			_value = newValue
			hasAppliedLatestChanges = false
			autosavePublisher?.send()
		}
	}

	private var _value: Value
	{
		willSet
		{
			objectWillChange.send()
		}
	}

	/// Call this function to manually save any changes to the record to the database
	@discardableResult
	public func commitChanges() throws -> WriteRequest.Result?
	{
		guard let db = database else { return nil }
		let result = try writeRequest.executeRequest(inDB: db, withMutableValue: &value)
		hasAppliedLatestChanges = true
		return result
	}

	private let autosavePublisher: PassthroughSubject<Void, Never>?
	private var autosaveSubscription: AnyCancellable?
	private var hasAppliedLatestChanges: Bool = false

	/// Initialise a GRDB mutable record with a value
	/// - parameter database: The database to save any changes to.
	/// - parameter value: The initial value
	/// - parameter autoSave: Whether to automatically commit any changes to the database. Default = true
	public init(database: DatabaseWriter?, value: Value, writeRequest: WriteRequest, autoSave: Bool = true)
	{
		self.database = database
		self.writeRequest = writeRequest
		_value = value

		if autoSave
		{
			autosavePublisher = PassthroughSubject()
			autosaveSubscription = autosavePublisher?
				.throttle(for: 0.1, scheduler: RunLoop.main, latest: true)
				.sink { [weak self] in
					guard let self = self else { return }
					do
					{
						guard !self.hasAppliedLatestChanges else { return }
						try self.commitChanges()
					}
					catch
					{
						// Ignoring errors for autosave
						print("Unable to save record due to error: \(error.localizedDescription)")
					}
				}
		}
		else
		{
			autosavePublisher = nil
		}
	}
}

/// A GRDBWriteRequest that either inserts or updates (if already exists) a MutablePersistableRecord
public struct SaveRequest<Value: MutablePersistableRecord>: GRDBWriteRequest
{
	public func onWrite(db: Database, value: Value) throws -> Value {
		do
		{
			try value.update(db)
			return value
		}
		catch PersistenceError.recordNotFound {
			var updated = value
			try updated.insert(db)
			return updated
		}
	}
}
