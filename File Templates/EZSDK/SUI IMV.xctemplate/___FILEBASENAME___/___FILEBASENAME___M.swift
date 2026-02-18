//  ___FILEHEADER___

import EZSUIPackKit

final class ___VARIABLE_productName:identifier___M: EZSUIPackM {
    var viewModel: ViewModel
    @MainActor final class ViewModel: ObservableObject {

    }

    weak let inputI: InputIProtocol?
    @MainActor protocol InputIProtocol: AnyObject {

    }

    let inputV: Void = ()

    init(inputI: InputI) {
        self.viewModel = .init()
        self.inputI = inputI
    }
}
