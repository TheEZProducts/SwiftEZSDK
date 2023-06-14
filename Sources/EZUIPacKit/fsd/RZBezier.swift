//
//  RZCubicBezier.swift
//  RZAnimationKit
//
//  Created by Александр Сенин on 27.04.2022.
//

import UIKit

public struct Bezier {
    public enum BezierType{
        case cubic(p1: CGPoint, p2: CGPoint)
        case custom(points: [CGPoint])
        
        public var points: [CGPoint]{
            switch self{
                case .cubic(let p1, let p2): return [.zero, p1, p2, .init(x: 1, y: 1)]
                case .custom(let points): return points
            }
        }
    }
    
    private var type: BezierType
    private var values: [(CGFloat, CGFloat)] = []
    private var values1: [CGFloat] = []
    private var accuracy: Int = 50
    private var lastX: CGFloat = 0
    private var needX: CGFloat = 0
    
    public init(type: BezierType, accuracy: Int = 50){
        self.type = type
        self.accuracy = accuracy
        setup()
    }
    
    private mutating func setup() {
        var values: [CGFloat] = []
        for i in 0...accuracy{
            let p = createPoint(CGFloat(i) / CGFloat(accuracy), type.points)
            setX(p.x, p.y, &values)
        }
        values1 = values
        values1.append(1)
    }
    
    private mutating func setX(_ x: CGFloat, _ y: CGFloat, _ arr: inout [CGFloat]){
        let lastY = arr.last ?? 0
        if x >= needX{
            var coof = (needX - lastX) / (x - lastX)
            if coof.isNaN{ coof = 0 }
            arr.append(lastY + ((y - lastY) * coof))
            lastX = needX
            needX += 1 / CGFloat(accuracy)
            setX(x, y, &arr)
        }
    }
    
    public func getValue(_ row: CGFloat) -> CGFloat{
        var row = row
        if row < 0 {row = 0}
        if row > 1 {row = 1}
    
        let intX = Int(row * CGFloat(accuracy))
        let fY = values1[intX]
        if intX + 1 >= values1.count{return fY}
        let sY = values1[intX + 1]
        let coof = (row - (CGFloat(intX) / CGFloat(accuracy))) / (1 / CGFloat(accuracy))
        let value = fY + ((sY - fY) * coof)
        return value
    }
    
    private func createPoint(_ row: CGFloat, _ points: [CGPoint]) -> CGPoint{
        if points.count <= 1 {return points.first ?? .zero}
        
        var newPoints = [CGPoint]()
        var oldPoint: CGPoint?
        for point in points{
            guard let oldPointL = oldPoint else {oldPoint = point; continue}
            newPoints.append(getPointInLine(p1: oldPointL, p2: point, value: row))
            oldPoint = point
        }
        
        return createPoint(row, newPoints)
    }
    
    private func getPointInLine(p1: CGPoint = .zero, p2: CGPoint = CGPoint(x: 1, y: 1), value: CGFloat) -> CGPoint{
        let square: CGSize = CGSize(width: (p1.x - p2.x) * value, height: (p1.y - p2.y) * value)
        return CGPoint(x: p1.x - square.width, y: p1.y - square.height)
    }
}
