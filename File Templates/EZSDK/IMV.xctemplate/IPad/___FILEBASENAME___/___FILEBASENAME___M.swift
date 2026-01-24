//  ___FILEHEADER___

import EZUIPackKit

class ___VARIABLE_productName:identifier___M: EZUIPackM {
    var viewModel: ViewModel
    @MainActor struct ViewModel {
        
    }
        
    weak let inputI: InputIProtocol?
    @MainActor protocol InputIProtocol: AnyObject {
      
    }
    
    weak let inputV: InputVProtocol?
    @MainActor protocol InputVProtocol: AnyObject {
      
    }
    
    required init(contextI: BaseContextI, contextV: BaseContextV) {
        viewModel = contextI.viewModel
        inputI = contextI.actions
        inputV = contextV.actions
    }
}
