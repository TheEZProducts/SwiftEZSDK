//
//  NSWindowConfig.swift
//  NSWindowConfig
//
//  Created by Александр Сенин on 23.07.2024.
//

import Foundation
import UIKit
//import Dynamic
//import MacOSUIComponents
//import MacOSHelpers

#if targetEnvironment(macCatalyst)
extension NSWindowConfig{
    public enum WindowType{
        case window
        case panel
    }
    
    public struct Level{
        public let rawValue: UInt32
        
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public static var normal: Self { .init(rawValue: 0) }
        public static var floating: Self { .init(rawValue: 3) }
        public static var submenu: Self { .init(rawValue: 3) }
        public static var tornOffMenu: Self { .init(rawValue: 3) }
        public static var modalPanel: Self { .init(rawValue: 8) }
        public static var mainMenu: Self { .init(rawValue: 24) }
        public static var statusBar: Self { .init(rawValue: 25) }
        public static var popUpMenu: Self { .init(rawValue: 101) }
        public static var screenSaver: Self { .init(rawValue: 1000) }
    }
    
    public struct StyleMask: OptionSet, @unchecked Sendable{
        public let rawValue: UInt32
        
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public static var borderless: Self { .init(rawValue: 0) }
        public static var titled: Self { .init(rawValue: 1 << 0) }
        public static var closable: Self { .init(rawValue: 1 << 1) }
        public static var miniaturizable: Self { .init(rawValue: 1 << 2) }
        public static var resizable: Self { .init(rawValue: 1 << 3) }
        public static var unifiedTitleAndToolbar: Self { .init(rawValue: 1 << 12) }

        @available(macOS 10.7, *)
        public static var fullScreen: Self { .init(rawValue: 1 << 14) }

        @available(macOS 10.10, *)
        public static var fullSizeContentView: Self { .init(rawValue: 1 << 15) }

        public static var utilityWindow: Self { .init(rawValue: 1 << 4) }
        public static var docModalWindow: Self { .init(rawValue: 1 << 6) }
        public static var nonactivatingPanel: Self { .init(rawValue: 1 << 7) }

        @available(macOS 10.6, *)
        public static var hudWindow: Self { .init(rawValue: 1 << 13) }
    }
    
    public struct TitleVisibility {
        public let rawValue: UInt32
        
        public init(rawBalue: UInt32) {
            self.rawValue = rawBalue
        }
        
        public static var hidden: Self { .init(rawBalue: 1 )}
        public static var visible: Self { .init(rawBalue: 0 )}
    }
}

public struct NSWindowConfig: @unchecked Sendable{
    private var _type: WindowType = .window
    private var _styleMask: StyleMask?
    private var _frame: CGRect?
    private var _color: UIColor?
    private var _level: Level?
    private var _title: String?
    private var _titleVisibility: TitleVisibility?
    
    private var _becomesKeyOnlyIfNeeded: Bool?
    private var _isOpaque: Bool?
    private var _isFloatingPanel: Bool?
    private var _hasShadow: Bool?
    private var _hidesOnDeactivate: Bool?
    private var _transparentTitlebar: Bool?
    private var _minimalSize: NSSize?
    
    private var _custom: ((NSObject) -> ())?
    
    public init(){}
    
    public func minimalSize(_ value: NSSize?) -> Self {
        var config = self
        config._minimalSize = value
        return config
    }
    
    public func titleVisibility(_ value: TitleVisibility?) -> Self {
        var config = self
        config._titleVisibility = value
        return config
    }
    
    public func setTitle(_ title: String?) -> Self {
        var config = self
        config._title = title
        return config
    }
    
    public func transparentTitlebar(_ value: Bool?) -> Self {
        var config = self
        config._transparentTitlebar = value
        return config
    }
    
    public func type(_ value: WindowType) -> Self{
        var config = self
        config._type = value
        return config
    }
    
    public func styleMask(_ value: StyleMask?) -> Self{
        var config = self
        config._styleMask = value
        return config
    }
    
    public func frame(_ value: CGRect?) -> Self{
        var config = self
        config._frame = value
        return config
    }
    
    public func color(_ value: UIColor?) -> Self{
        var config = self
        config._color = value
        return config
    }
    
    public func level(_ value: Level?) -> Self{
        var config = self
        config._level = value
        return config
    }
    
    public func becomesKeyOnlyIfNeeded(_ value: Bool?) -> Self{
        var config = self
        config._becomesKeyOnlyIfNeeded = value
        return config
    }
    
    public func isOpaque(_ value: Bool?) -> Self{
        var config = self
        config._isOpaque = value
        return config
    }
    
    public func hasShadow(_ value: Bool?) -> Self{
        var config = self
        config._hasShadow = value
        return config
    }
    
    public func isFloatingPanel(_ value: Bool?) -> Self{
        var config = self
        config._isFloatingPanel = value
        return config
    }
    
    public func hidesOnDeactivate(_ value: Bool?) -> Self{
        var config = self
        config._hidesOnDeactivate = value
        return config
    }
    
    
    public func custom(_ value: @escaping (NSObject) -> ()) -> Self{
        var config = self
        config._custom = value
        return config
    }
    
    @discardableResult
    public func apply(scene: UIWindowScene, completion: ((Dynamic) -> Void)? = nil) -> Bool {
        guard let window = Dynamic(scene)._UINSWindowProxy().attachedWindow.asObject else { return false }
        print("aaaa", "apply")
        if _type == .panel{
            print("asdfa", "panel")
            let dPanel = MyNSPanelMaker.get().initWithContentRect(CGRect(), styleMask: 0, backing: 2, defer: false)
//            let dPanel = Dynamic.UINSWindow.initWithContentRect(CGRect(), styleMask: 0, backing: 2, defer: false)
//            let dPanel = Dynamic(window)
            guard let panel = dPanel.asObject else { return false }
            
            
//            let id = dPanel.UINS_systemSceneIdentifier.asString
//            let id1 = dPanel.UINS_systemScenePersistentIdentifier.asString
//            
//            let wid = Dynamic(window).UINS_systemSceneIdentifier.asString
//            let wid1 = Dynamic(window).UINS_systemScenePersistentIdentifier.asString
//            print("ids-", "id", id)
//            print("ids-", "id1", id1)
//            print("ids-", "wid", wid)
//            print("ids-", "wid1", wid1)
            
//            foriOSMacContext
//            Dynamic(window).printMethods()
//            Dynamic(scene)._UINSWindowProxy().printMethods()
            
//
//            Dynamic(window).windowController.printMethods()
//            
//            Dynamic(scene)._UINSWindowProxy().printMethods()
            print("asdfa", Swift.type(of: Dynamic(scene)._UINSWindowProxy().attachedWindow.asObject!))
            
//            Dynamic(window).UINS_windowProxyForContentView.printMethods()
            
           
            
//            print("asdfa", "123")
            
//            Dynamic(window).windowController.setWindow(dPanel)
//            dPanel.windowController.printMethods()
//            Dynamic(window).windowController.printMethods()
            
            var conf = NSWindowConfig()
                .isOpaque(false)
                .color(.clear)
                .styleMask([.borderless, .nonactivatingPanel])
            
            _frame.map {
                conf = conf.frame($0)
            }
            
            conf.apply(scene: scene)
            
            if let _becomesKeyOnlyIfNeeded{
                dPanel.setBecomesKeyOnlyIfNeeded(_becomesKeyOnlyIfNeeded)
            }
            if let _isFloatingPanel{
                dPanel.setFloatingPanel(_isFloatingPanel)
            }
            
            
            self
                .frame(_frame ?? Dynamic(window).frame.asCGRect)
                .setup(panel)
            
            
            dPanel.setUINS_windowProxyForContentView(Dynamic(window).UINS_windowProxyForContentView.asObject)
            Dynamic(window).windowController.setWindow(panel)
            
//            dPanel.setContentView(Dynamic(window).contentView.asObject)
            
            Dynamic.NSCoreDragManager.sharedDragManager.registerWindow(panel, foriOSMacContext: nil)
            
            
            print(Swift.type(of: dPanel.contentView.window.asObject!))
            
//            Dynamic(window).windowController.printMethods()
            
            
//            Dynamic.NSApplication.sharedApplication.delegate.appLifecycleController.windowStateController._didCloseScene(scene)
            
//            Dynamic.UINSWindowStateController.printMethods()
//            Dynamic.UINSApplicationDelegate.printMethods()
//            Dynamic.NSApplication.printMethods()
            
//            Dynamic.NSPanel.printMethods()
//            Dynamic.UINSWindow.printMethods()
           
            
//            print("asdfa", Swift.type(of: Dynamic(window).windowController.asObject!))
//            print("asdfa", Swift.type(of: dPanel.windowController.asObject!))
            
//            dPanel.setContentView(Dynamic(window).contentView.asObject)
//            Dynamic(window).windowController.setWindow(dPanel)
            
            dPanel.makeKeyAndOrderFront(nil)
            

            
            completion?(dPanel)
            DispatchQueue.main.async {
                Dynamic(window).setIsVisible(false)
            }
            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//                print("asdfa", Dynamic(window).contentView.registeredDraggedTypes.asObject!)
//                print("asdfa", Dynamic(panel).contentView.registeredDraggedTypes.asObject!)
//            }
//            Dynamic.NSApplication.sharedApplication.delegate.appLifecycleController.windowStateController.didOpenWindowForScene(scene)
            
            return true
        }else{
            setup(window)
            completion?(Dynamic(window))
            return true
        }
        
        
    }
    
    @MainActor
    public func awaitOpeningApply(window: UIWindow, scene: UIWindowScene, completion: ((Dynamic) -> Void)? = nil){
        let tokenWrapper = SendableWrapper<Any?>(value: nil)
        tokenWrapper.value = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NSWindowDidUpdateNotification"),
            object: nil,
            queue: .main
        ) { notification in
            guard
                let nsWindow = Dynamic(scene)._UINSWindowProxy().attachedWindow.asObject,
                nsWindow == notification.object as? NSObject,
                let token = tokenWrapper.value
            else { return }
            NotificationCenter.default.removeObserver(token)
            apply(scene: scene, completion: completion)
        }
    }
    
    private func setup(_ window: NSObject){
        let dWindow = Dynamic(window)
        
        if let _styleMask{
            dWindow.setStyleMask(_styleMask.rawValue)
        }
        
        if let _frame{
            dWindow.setFrame(_frame, display: true)
        }
        
        if let _isOpaque{
            dWindow.setOpaque(_isOpaque)
        }
        
        if let _hasShadow{
            dWindow.setHasShadow(_hasShadow)
        }
        
        if let _hidesOnDeactivate{
            dWindow.setHidesOnDeactivate(_hidesOnDeactivate)
        }
        
        if let _transparentTitlebar {
            dWindow.titlebarAppearsTransparent = _transparentTitlebar
        }
        
        if let _title {
            dWindow.setTitle(_title)
        }
        
        if let _titleVisibility {
            dWindow.titleVisibility = _titleVisibility.rawValue
        }
        
        if let _color{
            let rgba = _color.rgba
            let color = Dynamic.NSColor.colorWithCalibratedRed(
                rgba.red,
                green: rgba.green,
                blue: rgba.blue,
                alpha: rgba.alpha
            ).asObject
            dWindow.setBackgroundColor(color)
        }
        
        if let _level{
            dWindow.setLevel(_level.rawValue)
        }
        
        
        if let _custom{
            _custom(window)
        }
        
        if let _minimalSize {
            dWindow.contentMinSize = _minimalSize
        }
    }
}



public struct MyNSPanelMaker {
    /// Регистрирует динамический подкласс NSPanel
    public static func registerDynamicPanelSubclass() {
        // 1. Выделяем класс-наследник от NSPanel
        guard
            let superclass = Dynamic.NSPanel.asAnyObject as? AnyClass,
            let dynamicClass = objc_allocateClassPair(
                superclass,
                "DynamicNSPanel",
                0
            )
        else { return }
        // 2. Создаём IMP для геттера canBecomeKey — всегда возвращает false
        let canBecomeKeyImp: @convention(c) (AnyObject, Selector) -> Bool = { _, _ in
            print("oh")
            return false
        }
        
        let selector = NSSelectorFromString("canBecomeKey")
        // 3. Добавляем метод canBecomeKey с сигнатурой "B@:"
        let result = class_addMethod(
            dynamicClass,
            selector,
            unsafeBitCast(canBecomeKeyImp, to: IMP.self),
            "B@:"
        )  // BOOL return + hidden args self, _cmd
        print("oh", result)
        
        // 4. Регистрируем новый класс в runtime
        objc_registerClassPair(dynamicClass)
    }

    
    static func get() -> Dynamic {
        .init(nil)
//        MacOSUIComponents.floatingWindow
    }
    
    /// Создаёт и возвращает экземпляр DynamicNSPanel
//    static func makePanel(
//        contentRect: NSRect,
//        styleMask: NSWindow.StyleMask = [.titled, .closable],
//                          backing: NSWindow.BackingStoreType = .buffered,
//                          defer flag: Bool = false) -> NSPanel? {
//        registerDynamicPanelSubclass()
//        // Получаем класс по имени и создаём экземпляр
//        guard let panelClass = NSClassFromString("DynamicNSPanel") as? NSPanel.Type else {
//            return nil
//        }
//        return panelClass.init(
//            contentRect: contentRect,
//            styleMask: styleMask,
//            backing: backing,
//            defer: flag
//        )
//    }
}

extension Bundle {
    /// Возвращает список всех ObjC-классов, объявленных в исполняемом файле бандла
    func allClassNames() -> [String] {
        guard let execURL = executableURL else { return [] }
        let imagePath = execURL.path
        var count: UInt32 = 0
        // Получаем массив C-строк с именами классов
        guard let classNames = objc_copyClassNamesForImage(imagePath, &count) else { return [] }
        defer { free(classNames) }
        
        return (0..<Int(count)).compactMap { idx in
            return String(cString: classNames[idx])
        }
    }
}



extension UIColor {
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (red, green, blue, alpha)
    }
}

class SendableWrapper<Value>: @unchecked Sendable{
    var value: Value
    
    init(value: Value) {
        self.value = value
    }
}
#endif
