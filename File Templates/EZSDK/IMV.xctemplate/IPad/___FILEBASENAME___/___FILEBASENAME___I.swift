//  ___FILEHEADER___

import EZUIPackKit

class ___VARIABLE_productName:identifier___I: EZUIPackI {
    let access = ___VARIABLE_productName:identifier___M.accessI
    
    func didInitialize() {}
    
    func makeContext() -> Mediator.ContextI {
        .init(actions: self, viewModel: .init())
    }
    
    func willOpen() {}
    func didOpen() {}
    
    func didInstall() {}
    
    func willClose() {}
    func didClose() {}
    
    func start() {}
    func didCreate() {}
}

extension ___VARIABLE_productName:identifier___I: ___VARIABLE_productName:identifier___M.InputIProtocol {
}
