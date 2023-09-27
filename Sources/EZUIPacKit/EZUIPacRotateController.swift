//
//  EZUIPacRotateController.swift
//
//  Created by Александр Сенин on 07.07.2020.
//  Copyright © 2020 Александр Сенин. All rights reserved.
//

#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
import UIKit

extension CGSize{
    var isHorizontal: Bool { width > height }
    
    mutating func swap(){
        self = swaped()
    }
    func swaped() -> CGSize{
        .init(width: height, height: width)
    }
}


extension UIInterfaceOrientation{
    var index: Int {
        switch self {
        case .portrait: return 0
        case .landscapeRight: return 1
        case .portraitUpsideDown: return 2
        case .landscapeLeft: return 3
        default: return -1
        }
    }
    
    static func getOrientation(at index: Int) -> UIInterfaceOrientation {
        var state = index % 4
        if state < 0 { state += 4 }
        switch state {
        case 0: return .portrait
        case 1: return .landscapeRight
        case 2: return .portraitUpsideDown
        case 3: return .landscapeLeft
        default: return .unknown
        }
    }
}

extension UIInterfaceOrientationMask{
    var orientations: [UIInterfaceOrientation]{
        switch self {
            case .all: return [.portrait, .portraitUpsideDown, .landscapeLeft, .landscapeRight]
            case .landscape: return [.landscapeRight, .landscapeLeft]
            case .portrait: return [.portrait]
            case .landscapeLeft: return [.landscapeLeft]
            case .landscapeRight: return [.landscapeRight]
            case .portraitUpsideDown: return [.portrait, .portraitUpsideDown]
            default: return []
        }
    }
    
    func isSupported(_ interfaceOrientation: UIInterfaceOrientation) -> Bool{
        orientations.contains(interfaceOrientation)
    }
}

extension EZUIPacRotateController{
    public class NotificationsStorage{
        public var notifications: [()->()] = []
        public func notify(){
            notifications.forEach{ $0() }
            notifications = []
        }
    }
}

struct EZUIPacRotateController{
    static func rotateAll(
        pack: (any EZUIPacProtocol),
        parentRotatin: RotateMode? = nil ,
        oldOrientation: UIInterfaceOrientation? = nil,
        newOrientation: UIInterfaceOrientation,
        notifications: NotificationsStorage? = nil
    ){
        let notificationsStorage = notifications ?? .init()
        let rotatin = rotate(
            pack: pack,
            parentRotatin: parentRotatin ?? .getRotete(from: oldOrientation, to: newOrientation),
            oldOrientation: oldOrientation ?? newOrientation,
            newOrientation: newOrientation,
            notifications: notificationsStorage
        )
        
        pack.children.forEach{
            rotateAll(
                pack: $0.value,
                parentRotatin: rotatin,
                oldOrientation: oldOrientation,
                newOrientation: newOrientation,
                notifications: notificationsStorage
            )
        }
        
        if notifications == nil{ notificationsStorage.notify() }
    }
    
    static func rotate(
        pack: (any EZUIPacProtocol),
        parentRotatin: RotateMode,
        oldOrientation: UIInterfaceOrientation,
        newOrientation: UIInterfaceOrientation,
        notifications: NotificationsStorage
    ) -> RotateMode{
        let (newOrintation, oldOrintation) = getOrientation(pack, newOrientation)
        let rootRotation = RotateMode.getRotete(from: oldOrientation, to: newOrientation)
        let interfaceRotation = RotateMode.getRotete(from: oldOrintation, to: newOrintation, priority: rootRotation.type)
        let rotation = interfaceRotation - parentRotatin
        let needResize = oldOrintation.isLandscape != newOrintation.isLandscape
        
        pack.container.rotate(pi: rotation.pi, needToResize: needResize)
        
//        let container = pack.container
//        if rotation.value != 0{
//            setTransform(container, rotation.pi)
//        }
//        var size = container.frame.size
//        if needResize {
//            size.swap()
////            container.frame = .init(origin: .zero, size: container.superview?.bounds.size ?? container.bounds.size)
//        }
//        container.superview?.frame.size = size
        
        pack.currentOrientation = newOrintation
        if oldOrintation != newOrintation, pack.isStarted{
            notifications.notifications.append {
                pack.didRotateAction(oldOrientation: oldOrintation, newOrientation: newOrintation)
            }
        }
        return interfaceRotation
    }
    
    private static func getOrientation(
        _ pack: (any EZUIPacProtocol),
        _ deviceOrientation: UIInterfaceOrientation
    ) -> (newPackOrintation: UIInterfaceOrientation, oldPackOrintation: UIInterfaceOrientation) {
        var newPackOrintation = deviceOrientation
        if !pack.supportedOrientations.isSupported(newPackOrintation){
            newPackOrintation =
                pack.currentOrientation ??
                pack.supportedOrientations.orientations.first ??
                .portrait
        }
        let oldPackOrintation = pack.currentOrientation ??
            pack.parent?.currentOrientation ??
            deviceOrientation
        return (newPackOrintation, oldPackOrintation)
    }
}

struct RotateMode{
    enum RotateType{
        case left
        case right
        case non

        func createMode(value: Int) -> RotateMode{
            switch self{
                case .left: return .left(value)
                case .right: return .right(value)
                case .non: return .non
            }
        }
    }
    var value: Int = 0
    var pi: CGFloat { (.pi / 2) * CGFloat(value) }
    var type: RotateType {
        switch value{
            case ..<0:  return .left
            case 0:     return .non
            case 1...:  return .right
            default: return .non
        }
    }

    init(){}
    init(value: Int){self.value = value}
    static func left(_ value: Int) -> Self{ .init(value: -value) }
    static func right(_ value: Int) -> Self{ .init(value: value) }
    static var non: Self { .init(value: 0) }

    static func -=(left: inout Self, right: Self){
        left.value -= right.value
    }

    static func -(left: Self, right: Self) -> Self{
        .init(value: left.value - right.value)
    }

    static func +=(left: inout Self, right: Self){
        left.value += right.value
    }

    static func +(left: Self, right: Self) -> Self{
        .init(value: left.value + right.value)
    }

    func getOrientation(old rotation: UIInterfaceOrientation) -> UIInterfaceOrientation{
        .getOrientation(at: rotation.index - value)
    }

    static func getRotete(
        from: UIInterfaceOrientation?,
        to: UIInterfaceOrientation,
        priority: RotateType = .right
    ) -> Self{
        guard let from = from else { return .init(value: 0)}
        var new = to.index - from.index
        if new == 3{
            new = -1
        }else if new == -3{
            new = 1
        }else if new == -2, priority == .right{
            new = 2
        }else if new == 2, priority == .left{
            new = -2
        }
        return .init(value: new)
    }
}
#endif




//
//
//public class EZRotater: UIView{
//    var mateOrientation: UIInterfaceOrientation?
//    var mateGoodOrientation: [UIInterfaceOrientation] {
//        mateController?.supportedInterfaceOrientations.orientations ?? []
//    }
//    static var lastOrintation: UIInterfaceOrientation = UIApplication.orientation
//    static var oldOrintation: UIInterfaceOrientation = UIApplication.orientation
//    static var isRotate: Bool = false
//
//    static func resizeAllChild(
//        isInstall: Bool = false,
//        child: EZUIPacControllerNGProtocol,
//        parentOrientation: UIInterfaceOrientation,
//        parentRotatin: RotateMode,
//        transitionDuration: CGFloat? = nil
//    ){
//        let parentRotatin = child.rotater?.rotateMate(
//            isInstall: isInstall,
//            parentRotatin: parentRotatin,
//            parentOrientation: parentOrientation,
//            transitionDuration: transitionDuration
//        ) ?? .non
//
//        for childL in child.children{
//            if let childL = childL as? EZUIPacControllerNGProtocol{
//                resizeAllChild(
//                    isInstall: isInstall,
//                    child: childL,
//                    parentOrientation: child.rotater?.mateOrientation ?? .portrait,
//                    parentRotatin: parentRotatin,
//                    transitionDuration: transitionDuration
//                )
//
//            }
//        }
//    }
//
    
//
//
//    //MARK: - Orientation
//
//    //MARK: - Animation Body
    
//
//
//
//    private static var rotatingUIPacC: [EZUIPacControllerNGProtocol] = []
//    static func rotate(){
//        for uiPacC in rotatingUIPacC{
//            uiPacC.rotate()
//        }
//        rotatingUIPacC = []
//    }
//
//    public init(viewController: UIViewController) {
//        let view: UIView = viewController.view
//        super.init(frame: view.frame)
//        let superV = view.superview
//        superV?.addSubview(self)
//
//        superV?.ezFrame.add{[weak self, weak view, weak viewController] in
//            guard let self = self, let view = view else {return}
//            if EZRotater.isRotate {return}
//
//            if self.frame.size != $0.new.size{
//                self.frame.size = $0.new.size
//            }
//            if view.frame.size != $0.new.size{
//                view.frame.size = $0.new.size
//            }
//            (viewController as? EZUIPacControllerNGProtocol)?.resize()
//        }
//
//        view.frame.origin = .zero
//        addSubview(view)
//        mate = view
//        if let viewController = viewController as? EZUIPacControllerNGProtocol{
//            mateController = viewController
//        }
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//
//
//
//
//


