//
//  File.swift
//  
//
//  Created by Александр Сенин on 30.05.2023.
//

import Foundation

infix operator <-
prefix operator <-

@available(watchOS 6.0, *)
@available(tvOS 13.0, *)
@available(iOS 13.0, *)
@available(macOS 10.15, *)
extension AsyncStream{
    static func create() -> (Self, Continuation){
        var cont: Continuation!
        return (Self{cont = $0}, cont)
    }
}

@available(watchOS 6.0, *)
@available(tvOS 13.0, *)
@available(iOS 13.0, *)
@available(macOS 10.15, *)
public struct EZChannel<Element>: @unchecked Sendable{
    public enum State{
        case finish
    }
    
    private(set) var stream: AsyncStream<Element>
    private(set) var continuation: AsyncStream<Element>.Continuation
    
    public init(){
        (stream, continuation) = AsyncStream<Element>.create()
    }
    
    public static func <-(l: Self, r: Element){
        l.continuation.yield(r)
    }
    
    public static func <-(l: Self, r: State){
        l.continuation.finish()
    }
    
    public static prefix func <-(r: Self) async -> Element?{
        var i = r.makeAsyncIterator()
        return await i.next()
    }
    
    @discardableResult
    public static func <-(l: inout Element?, r: Self) async -> Bool{
        var i = r.makeAsyncIterator()
        l = await i.next()
        return l != nil
    }
    
    public func addHandler(
        handler: @escaping (Element) async -> () = {_ in},
        completion: @escaping (Element?) async -> () = {_ in}
    ){
        Task{
            var last: Element?
            for await value in stream{
                last = value
                await handler(value)
            }
            await completion(last)
        }
    }
}

@available(watchOS 6.0, *)
@available(tvOS 13.0, *)
@available(iOS 13.0, *)
@available(macOS 10.15, *)
extension EZChannel: AsyncSequence{
    public func makeAsyncIterator() -> AsyncStream<Element>.Iterator { stream.makeAsyncIterator() }
}
