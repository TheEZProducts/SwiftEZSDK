//
//  EZAnimationCurve.swift
//  EZAnimationKit
//
//  Created by Александр Сенин on 27.04.2022.
//

import UIKit

public class EZAnimationCurve{
    public func curveAction(_ value: CGFloat) -> CGFloat { value }
    
    public class var standart: EZAnimationCurve { EZAnimationCurve() }
    public class var ezDown: EZAnimationCurve { EZAnimationCurveEzDown() }
    public class func custom(_ action: @escaping (_ value: CGFloat) -> CGFloat) -> EZAnimationCurve { EZAnimationCurveCustom(action) }
    public class func bezier(_ p1: CGPoint, _ p2: CGPoint) -> EZAnimationCurve {
        let curve = Bezier(type: .cubic(p1: p1, p2: p2))
        return .custom { curve.getValue($0) }
    }
    public class func bezier(_ points: [CGPoint]) -> EZAnimationCurve {
        let curve = Bezier(type: .custom(points: points))
        return .custom { curve.getValue($0) }
    }
}

public class EZAnimationCurveEzDown: EZAnimationCurve{
    public override func curveAction(_ value: CGFloat) -> CGFloat {(2 - (1 * value)) * value}
}

public class EZAnimationReverstCurve: EZAnimationCurve{
    public var curve: EZAnimationCurve
    public init(_ curve: EZAnimationCurve) { self.curve = curve }
    public override func curveAction(_ value: CGFloat) -> CGFloat { 1 - curve.curveAction(value) }
}

public class EZAnimationCurveCustom: EZAnimationCurve{
    private var action: (_ value: CGFloat) -> CGFloat = {$0}
    
    public init(_ action: @escaping (_ value: CGFloat) -> CGFloat){ self.action = action }
    public override func curveAction(_ value: CGFloat) -> CGFloat { action(value) }
}
