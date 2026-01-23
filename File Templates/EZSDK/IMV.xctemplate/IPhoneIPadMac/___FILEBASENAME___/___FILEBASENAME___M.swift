//  ___FILEHEADER___

import EZUIPackKit

class ___VARIABLE_productName:identifier___M: EZUIPackM {
    var viewModel: ViewModel
    @MainActor struct ViewModel {
        
    }
        
    weak let inputI: IAction?
    @MainActor protocol IAction: AnyObject {
      
    }
    
    weak let inputV: VAction?
    @MainActor protocol VAction: AnyObject {
      
    }
    
    required init(contextI: BaseContextI, contextV: BaseContextV) {
        viewModel = contextI.viewModel
        inputI = contextI.actions
        inputV = contextV.actions
    }
}
