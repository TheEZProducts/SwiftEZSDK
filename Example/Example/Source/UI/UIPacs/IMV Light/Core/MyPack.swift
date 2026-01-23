//
//  MyPack.swift
//  Example
//
//  Created by Александр Сенин on 25.12.2025.
//

import UIKit
import Combine

typealias MyPack = IMVMaker<MyPackI, MyPackM, MyPackV>

@MainActor
final class MyPackI: UIViewController, InteractorProtocol {
    let access: MyPackM.AccessI
    private let rootView: UIView

    override func loadView() {
        view = rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        access.vActions?.create()
    }

    required init(mediator: MyPackM, view: some ViewProtocol) {
        self.access = mediator.accessI
        self.rootView = view
        super.init(nibName: nil, bundle: nil)
        mediator.inputI = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MyPackI: MyPackM.inputI {
    func didCreate() {
        access.viewModel.counter = access.storage.counter
        access.viewModel.title = "MyPack demo"
    }

    func didTapIncrement() {
        access.storage.counter += 1
        access.viewModel.counter = access.storage.counter
    }

    func didTapReset() {
        access.storage.counter = 0
        access.viewModel.counter = 0
    }
}

@MainActor
final class MyPackM: MediatorProtocol {
    var storage: Storage = .init()
    struct Storage {
        var counter: Int = 0
    }

    var viewModel: ViewModel = .init()
    final class ViewModel {
        @Published var title: String
        @Published var counter: Int

        init(title: String = "MyPack demo", counter: Int = 0) {
            self.title = title
            self.counter = counter
        }
    }

    weak var inputI: inputI?
    @MainActor protocol inputI: AnyObject {
        func didCreate()
        func didTapIncrement()
        func didTapReset()
    }

    weak var vActions: VActions?
    @MainActor protocol VActions: AnyObject {
        func create()
    }
}

@MainActor
final class MyPackV: UIView, ViewProtocol {
    let access: MyPackM.AccessV

    private let titleLabel = UILabel()
    private let counterLabel = UILabel()
    private let incrementButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
    private let stack = UIStackView()

    private var didSetup = false
    private var cancellables = Set<AnyCancellable>()

    required init(mediator: MyPackM) {
        self.access = mediator.accessV
        super.init(frame: .zero)
        mediator.vActions = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onIncrement() {
        access.inputI?.didTapIncrement()
    }

    @objc private func onReset() {
        access.inputI?.didTapReset()
    }
}

extension MyPackV: MyPackM.VActions {
    func create() {
        guard !didSetup else { return }
        didSetup = true

        setupAppearance()
        setupSubviews()
        setupLayout()
        setupActions()

        // Вешаем реактивные подписки на ViewModel (store UI-состояния)
        bind(to: access.viewModel)

        // Сообщаем интерактору, что View готова
        access.inputI?.didCreate()
    }

    private func setupSubviews() {
        let buttons = UIStackView(arrangedSubviews: [incrementButton, resetButton])
        buttons.axis = .horizontal
        buttons.spacing = 12
        buttons.distribution = .fillEqually

        stack.axis = .vertical
        stack.spacing = 16
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(counterLabel)
        stack.addArrangedSubview(buttons)

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }

    private func setupAppearance() {
        backgroundColor = .systemBackground

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center

        counterLabel.font = .preferredFont(forTextStyle: .title1)
        counterLabel.textAlignment = .center

        incrementButton.setTitle("Increment", for: .normal)
        resetButton.setTitle("Reset", for: .normal)
    }

    private func setupActions() {
        incrementButton.addTarget(self, action: #selector(onIncrement), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(onReset), for: .touchUpInside)
    }

    private func bind(to viewModel: MyPackM.ViewModel) {
        cancellables.removeAll()

        viewModel.$title
            .receive(on: RunLoop.main)
            .sink { [weak self] title in
                self?.titleLabel.text = title
            }
            .store(in: &cancellables)

        viewModel.$counter
            .receive(on: RunLoop.main)
            .sink { [weak self] counter in
                self?.counterLabel.text = "Counter: \(counter)"
            }
            .store(in: &cancellables)

        titleLabel.text = viewModel.title
        counterLabel.text = "Counter: \(viewModel.counter)"
    }
}
