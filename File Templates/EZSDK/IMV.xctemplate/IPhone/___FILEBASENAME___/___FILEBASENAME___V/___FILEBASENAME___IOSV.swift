//  ___FILEHEADER___

import UIKit

import EZUIPackKit

class ___VARIABLE_productName:identifier___IOSV: EZUIPackV {
    let access = ___VARIABLE_productName:identifier___M.accessV
    
    func willOpen() {}
    func animateOpen() {}
    func didOpen() {}
    
    func didInstall() {}
    
    func willClose() {}
    func animateClose() {}
    func didClose() {}
    
    func didInitialize() {}
    
    func makeContext() -> Mediator.ContextV {
        .init(actions: self)
    }
    
    func create() {}
}

extension ___VARIABLE_productName:identifier___IOSV: ___VARIABLE_productName:identifier___M.VAction {
}
