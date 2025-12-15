//
//  EZAccess.swift
//  EZSDK
//
//  Created by Александр Сенин on 11.12.2025.
//

import Foundation

#if hasFeature(Lifetimes)
public struct EZAccess<Value>: ~Copyable, ~Escapable where Value: ~Copyable {
    private let ptr: UnsafeMutablePointer<Value>

    @_lifetime(borrow ptr)
    public init(_ ptr: borrowing UnsafeMutablePointer<Value>) {
        self.ptr = copy ptr
    }

    public var value: Value {
        _read { yield ptr.pointee }
        nonmutating _modify { yield &ptr.pointee }
    }
}
#else
public struct EZAccess<Value>: ~Copyable where Value: ~Copyable {
    private let ptr: UnsafeMutablePointer<Value>

    public init(_ ptr: borrowing UnsafeMutablePointer<Value>) {
        self.ptr = copy ptr
    }

    public var value: Value {
        _read{ yield ptr.pointee }
        nonmutating _modify { yield &ptr.pointee }
    }
}
#endif
