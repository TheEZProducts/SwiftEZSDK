//
//  ObservableObject + willChangeSync.swift
//  EZSDK
//
//  Created by Александр Сенин on 18.02.2026.
//

#if canImport(Combine)
import Combine

extension ObservableObject {
    func willChangeSync(receiveValue: @escaping () -> Void) -> AnyCancellable {
        objectWillChange.sink { _ in
            receiveValue()
        }
    }
}
#endif
