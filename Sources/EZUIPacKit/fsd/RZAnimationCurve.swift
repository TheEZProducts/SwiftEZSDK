//
//  RZAnimationCurve.swift
//  RZAnimationKit
//
//  Created by Александр Сенин on 27.04.2022.
//

import UIKit

public class RZAnimationCurve{
    public func curveAction(_ value: CGFloat) -> CGFloat { value }
    
    public class var standart: RZAnimationCurve { RZAnimationCurve() }
    public class var ezDown: RZAnimationCurve { RZAnimationCurveEzDown() }
    public class func custom(_ action: @escaping (_ value: CGFloat) -> CGFloat) -> RZAnimationCurve { RZAnimationCurveCustom(action) }
    public class func bezier(_ p1: CGPoint, _ p2: CGPoint) -> RZAnimationCurve {
        let curve = Bezier(type: .cubic(p1: p1, p2: p2))
        return .custom { curve.getValue($0) }
    }
    public class func bezier(_ points: [CGPoint]) -> RZAnimationCurve {
        let curve = Bezier(type: .custom(points: points))
        return .custom { curve.getValue($0) }
    }
}

public class RZAnimationCurveEzDown: RZAnimationCurve{
    public override func curveAction(_ value: CGFloat) -> CGFloat {(2 - (1 * value)) * value}
}

public class RZAnimationReverstCurve: RZAnimationCurve{
    public var curve: RZAnimationCurve
    public init(_ curve: RZAnimationCurve) { self.curve = curve }
    public override func curveAction(_ value: CGFloat) -> CGFloat { 1 - curve.curveAction(value) }
}

public class RZAnimationCurveCustom: RZAnimationCurve{
    private var action: (_ value: CGFloat) -> CGFloat = {$0}
    
    public init(_ action: @escaping (_ value: CGFloat) -> CGFloat){ self.action = action }
    public override func curveAction(_ value: CGFloat) -> CGFloat { action(value) }
}
