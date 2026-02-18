//  ___FILEHEADER___

import SwiftUI
import EZSUIPackKit

enum ___VARIABLE_productName:identifier___ {
    @MainActor
    static func make() -> some View {
        EZSUIPack(
            interactor: { ___VARIABLE_productName:identifier___I() },
            mediator: { inputI, _ in ___VARIABLE_productName:identifier___M(inputI: inputI) },
            view: { ___VARIABLE_productName:identifier___V() }
        )
    }
}
