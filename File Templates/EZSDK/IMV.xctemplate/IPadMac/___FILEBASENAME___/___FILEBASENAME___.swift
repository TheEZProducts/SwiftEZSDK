//  ___FILEHEADER___

import EZUIPackKit

enum ___VARIABLE_productName:identifier___ {
    @MainActor
    static func make() -> ___VARIABLE_productName:identifier___I {
        EZPackMaker.make(
            interactor: { ___VARIABLE_productName:identifier___I() },
            mediator: { inputI, inputV in ___VARIABLE_productName:identifier___M(inputI: inputI, inputV: inputV) },
            view: { ___VARIABLE_productName:identifier___V() }
        )
    }
}


class ___VARIABLE_productName:identifier___V: EZUIPackPlatformsV<___VARIABLE_productName:identifier___M> {
    override var iPadOS: (any EZUIPackViewProtocol<___VARIABLE_productName:identifier___M>)? {
        ___VARIABLE_productName:identifier___IPadOSV()
    }
    override var macCatalyst: (any EZUIPackViewProtocol<___VARIABLE_productName:identifier___M>)? {
        ___VARIABLE_productName:identifier___MacCatalystV()
    }
}
