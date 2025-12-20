/// Contract for constant-storage property macros.
///
/// This protocol exists to support a reusable property macro pattern where a *stored* property
/// is rewritten into a *computed* property plus a **constant** backing storage (`let _name`).
/// Using a `let` backing field avoids common `Sendable` issues of traditional stored
/// `@propertyWrapper` variables in classes and `static` globals.
///
/// ## Example: defining a storage type and its macro
/// A constant-storage macro is declared in two forms:
/// - a non-generic form (type inferred from the property),
/// - and a generic form (type spelled explicitly).
///
/// The implementation is universal and should be referenced as:
/// - `module: "EZMacros"`
/// - `type: "EZConstantPropertyWrapperMacro"`
///
/// In this example the macro name matches the storage type name (`LockedBox`), so `@LockedBox`
/// produces backing storage of type `LockedBox<WrappedValue>`.
///
/// ```swift
/// @attached(accessor)
/// @attached(peer, names: prefixed(`$`), prefixed(`_`))
/// public macro LockedBox(option: Int = 0) =
///     #externalMacro(module: "EZMacros", type: "EZConstantPropertyWrapperMacro")
///
/// @attached(accessor)
/// @attached(peer, names: prefixed(`$`), prefixed(`_`))
/// public macro LockedBox<T>(option: Int = 0) =
///     #externalMacro(module: "EZMacros", type: "EZConstantPropertyWrapperMacro")
///
/// public final class LockedBox<Value>: EZConstantPropertyWrapperProtocol {
///     public typealias WrappedValue = Value
///     public typealias ProjectedValue = Reader
///
///     public struct Reader {
///         fileprivate let box: LockedBox
///         public func get() -> Value { box.wrappedValue }
///     }
///
///     public var wrappedValue: Value { get nonmutating set }
///     public var projectedValue: Reader { .init(box: self) }
///
///     public init(wrappedValue: Value, option: Int = 0) {
///         self.wrappedValue = wrappedValue
///     }
/// }
/// ```
///
/// ## Using the macro
/// You can specify the value type either on the property:
/// ```swift
/// @LockedBox(option: 42) var value: Int = 123
/// ```
/// or by using the generic macro form:
/// ```swift
/// @LockedBox<Int>(option: 42) var value = 123
/// ```
///
/// ## Conceptual expansion
/// Conceptually, the macro expands the declaration into something equivalent to:
/// ```swift
/// var value: Int {
///     _read { yield _value.wrappedValue }
///     _modify { yield &_value.wrappedValue }
/// }
///
/// var $value: LockedBox<Int>.ProjectedValue {
///     _read { yield _value.projectedValue }
/// }
///
/// // Extra macro arguments are appended after `wrappedValue`.
/// let _value: LockedBox<Int> = LockedBox(wrappedValue: 123, option: 42)
/// ```
/// (exact details depend on the macro implementation).
///
/// ## Access control mapping
/// The macro generates two additional symbols:
/// - `$value` (the projected value)
/// - `_value` (the backing storage)
///
/// A common access-control strategy is:
/// - The main property keeps its original modifiers (e.g. `public internal(set)`).
/// - `$value` keeps the property's *main* access level (e.g. `public`).
/// - `_value` uses the most restrictive *setter* access level (e.g. `internal` for `public internal(set)`).
///
/// This keeps the projection readable where the property is readable, while still respecting
/// restricted setters by not exposing the backing storage more broadly than necessary.
///
/// ### Example
/// ```swift
/// @LockedBox public internal(set) var text: String = "Hello"
///
/// // Conceptually:
/// public var $text: LockedBox<String>.ProjectedValue { ... }
/// internal let _text: LockedBox<String> = LockedBox(wrappedValue: "Hello")
/// ```
///
/// ## What a conforming storage type must provide
/// A type conforming to `EZConstantPropertyWrapperProtocol` is intended to be used as that backing
/// storage (`_value`). For the macro to work, the conformer must expose:
///
/// - `wrappedValue` with a **nonmutating** setter.
///   This is the key requirement that allows the backing storage to be a `let` constant.
/// - `projectedValue` for the `$property` projection.
///
/// Note: the exact forwarding rules and access-control mapping are defined by the macro,
/// not by this protocol.
public protocol EZConstantPropertyWrapperProtocol {
    associatedtype WrappedValue
    associatedtype ProjectedValue
    
    var wrappedValue: WrappedValue { get nonmutating set }
    var projectedValue: ProjectedValue { get }
}
