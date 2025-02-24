//
//  EZTransition.swift
//  UIPackkages
//
//  Created by Александр Сенин on 15.02.2025.
//

import Foundation
import UIKit

public protocol EZTransitionContextProtocol{}

public protocol EZTransitionProtocol<Context>{
    associatedtype Context: EZTransitionContextProtocol
    var context: Context { get set }
    
    @MainActor
    @discardableResult
    func transit() -> Bool 
}

@MainActor
public struct EZTransition<Container>{
    private(set) var container: Container
}

extension EZTransition<UIViewController>{
    public init(_ container: UIViewController) {
        self.container = container
    }
}

extension EZTransition<EZContainerView>{
    public init(_ container: EZContainerView) {
        self.container = container
    }
}

