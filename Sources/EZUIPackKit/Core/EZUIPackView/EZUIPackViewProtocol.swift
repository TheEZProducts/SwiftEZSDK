//
//  EZUIPackV.swift
//  UIPackkages
//
//  Created by Александр Сенин on 08.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

#if canImport(SwiftUI)
import SwiftUI
#endif

public protocol EZUIPackViewProtocol<Mediator>: EZViewProtocol {
#if !os(tvOS) && !os(watchOS)
    var supportedInterfaceOrientations: UIInterfaceOrientationMask? { get }
    var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation? { get }
    
    
    var preferredStatusBarStyle: UIStatusBarStyle? { get }
    var prefersStatusBarHidden: Bool? { get }
    var preferredStatusBarUpdateAnimation: UIStatusBarAnimation? { get }
#endif
    
#if !os(watchOS)
    func getView() -> EZView
#endif
    
    func didInitialize()
    func willOpen()
    func animateOpen()
    func didOpen()
    func didInstall()
    func willClose()
    func animateClose()
    func didClose()
    
    
    func viewDidLoad()
    func viewWillAppear(_ animated: Bool)
    @available(iOS 13.0, tvOS 13.0, *)
    func viewIsAppearing(_ animated: Bool)
    func viewDidAppear(_ animated: Bool)
    func viewWillDisappear(_ animated: Bool)
    func viewDidDisappear(_ animated: Bool)
}

extension EZUIPackViewProtocol {
#if !os(tvOS) && !os(watchOS)
    public var supportedInterfaceOrientations: UIInterfaceOrientationMask? { nil }
    public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation? { nil }
    
    public var preferredStatusBarStyle: UIStatusBarStyle? { nil }
    public var prefersStatusBarHidden: Bool? { nil }
    public var preferredStatusBarUpdateAnimation: UIStatusBarAnimation? { nil }
#endif
    
    public func didInitialize(){}
    public func willOpen(){}
    public func animateOpen(){}
    public func didOpen(){}
    public func didInstall(){}
    public func willClose(){}
    public func animateClose(){}
    public func didClose(){}
    
    
    public func viewDidLoad(){}
    public func viewWillAppear(_ animated: Bool){}
    @available(iOS 13.0, tvOS 13.0, *)
    public func viewIsAppearing(_ animated: Bool){}
    public func viewDidAppear(_ animated: Bool){}
    public func viewWillDisappear(_ animated: Bool){}
    public func viewDidDisappear(_ animated: Bool){}
}

#endif
