//
//  SceneDelegate.swift
//  Example
//
//  Created by Александр Сенин on 04.06.2023.
//

import UIKit
import EZUIPackKit

extension EZUIPackViewProtocol{
    var supportedOrientations: UIInterfaceOrientationMask {.portrait}
}

final class ColorVC: UIViewController {
    init(_ title: String, _ color: UIColor) {
        super.init(nibName: nil, bundle: nil)
//        self.title = title
        view.backgroundColor = color
    }
    required init?(coder: NSCoder) { fatalError() }
}

#if targetEnvironment(macCatalyst)
import AppKit
#endif

//class SceneDelegate: UIResponder, UIWindowSceneDelegate {
//
//    var window: UIWindow?
//    var any: Any?
////    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
////        
//////        let v = UIView()
//////        any = v.layer.observe(\.position, options: [.old, .new]) {[weak self] (view, value) in
//////            print("aaa", value)
//////        }
//////
//////        v.layer.bounds = .init(x: 1, y: 1, width: 1, height: 1)
//////
////        
////
//////        if let windowScene = scene as? UIWindowScene {
//////            let window = UIWindow(windowScene: windowScene)
//////            window.rootViewController = MainPack()
//////            window.makeKeyAndVisible()
//////            self.window = window
//////        }
////        
////        if let windowScene = scene as? UIWindowScene {
////            let window = UIWindow(windowScene: windowScene)
////            
////            let split = UISplitViewController(style: .doubleColumn)
//////            split.preferredDisplayMode = .oneBesideSecondary
////            split.primaryBackgroundStyle = .sidebar
//////            split.preferredSplitBehavior = .tile
////            split.primaryEdge = .trailing
////            
////            let v1 = UIViewController()
////            v1.view.backgroundColor = .red
////            split.setViewController(v1, for: .secondary)
////            
////            let v2 = UIViewController()
////            v2.view.backgroundColor = .blue
////            split.setViewController(v2, for: .primary)
////            
//////            let v3 = UIViewController()
//////            v3.view.backgroundColor = .green
//////            split.setViewController(v3, for: .compact)
////            
//////            let v4 = UIViewController()
//////            v4.view.backgroundColor = .yellow
//////            split.setViewController(v4, for: .supplementary)
////            
////            window.rootViewController = split
////            window.makeKeyAndVisible()
////            self.window = window
////        }
////        
//////        if let windowScene = scene as? UIWindowScene {
////////            if let titlebar = windowScene.titlebar {
////////                let tb = NSToolbar(identifier: "MainToolbar")
//////////                tb.centeredItemIdentifiers = []       // убираем центр-группу
//////////                tb.showsBaselineSeparator = false     // опционально: убираем нижнюю полоску
////////                titlebar.toolbar = tb
//////////                titlebar.titleVisibility = .hidden    // по желанию
////////                // titlebar.toolbarStyle = .unified    // можно задать стиль
////////            }
//////            let tab = UITabBarController()
//////            let c = UIViewController()
//////            c.view.backgroundColor = .red
//////            tab.setViewControllers([c], animated: false)
//////            c.tabBarItem = .init(title: "Test", image: nil, tag: 1)
//////            
//////            if #available(macCatalyst 18.0, *) {
////////                tab.isTabBarHidden = true
//////                
////////                tab.tabBar.isHidden = true
////////                tab.tabs = []
//////                tab.mode = .tabBar
////////                tab.setTabBarHidden(true, animated: false)
//////            }
//////            let nav = UINavigationController(rootViewController: tab)
////////            nav.pushViewController(UIViewController(), animated: false)
//////            let window = UIWindow(windowScene: windowScene)
//////            window.rootViewController = nav
//////            window.makeKeyAndVisible()
//////            Task {
//////                try? await Task.sleep(for: .seconds(5))
//////                if #available(macCatalyst 18.0, *) {
//////                    UIView.animate(withDuration: 1) {
//////                        tab.mode = .tabSidebar
//////                    }
//////                    
//////                    //                tab.setTabBarHidden(true, animated: false)
//////                    //                tab.isTabBarHidden = true
//////                    //                tab.tabBar.isHidden = true
//////                }
//////            }
//////            self.window = window
//////        }
////        
//////        if let windowScene = scene as? UIWindowScene {
//////            if let titlebar = windowScene.titlebar {
//////                let tb = NSToolbar(identifier: "MainToolbar")
////////                tb.centeredItemIdentifiers = []       // убираем центр-группу
////////                tb.showsBaselineSeparator = false     // опционально: убираем нижнюю полоску
//////                titlebar.toolbar = tb
////////                titlebar.titleVisibility = .hidden    // по желанию
//////                // titlebar.toolbarStyle = .unified    // можно задать стиль
//////            }
//////            
//////            let tab = UITabBarController()
//////            let nav = UINavigationController(rootViewController: UIViewController())
//////            tab.setViewControllers([nav], animated: false)
//////            tab.toolbarItems = nil
//////            nav.setToolbarHidden(true, animated: false)
//////            let window = UIWindow(windowScene: windowScene)
//////            window.rootViewController = tab
//////            window.makeKeyAndVisible()
//////            self.window = window
//////        }
////    }
//    private let split = UISplitViewController(style: .tripleColumn)
//    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
//        
//        guard let ws = scene as? UIWindowScene else { return }
//
//        
//        // Контент слева, «меню» справа (primary)
//        let split = UISplitViewController(style: .doubleColumn)
//
//        split.primaryEdge = .trailing
//        split.primaryBackgroundStyle = .sidebar
//        split.preferredSplitBehavior = .tile
//        split.preferredDisplayMode = .oneBesideSecondary   // важно!
//
//        let content = ColorVC("Контент (слева)", .systemBlue)
//        let menu    = ColorVC("Меню (справа)",  .systemGreen)
//
//        split.setViewController(menu,    for: .primary)    // правая колонка
//        split.setViewController(content, for: .secondary)  // левая колонка
//
//        // ширины/границы, чтобы система не уходила в overlay
//        split.minimumPrimaryColumnWidth = 260
//        split.maximumPrimaryColumnWidth = 480
//        split.preferredPrimaryColumnWidthFraction = 0.25
//
//        // убедимся, что колонка показана (иначе toggle покажет её как overlay)
//        DispatchQueue.main.async {
//            split.show(.primary)
//        }
//
//        // окно
//        let win = UIWindow(windowScene: ws)
//        win.rootViewController = split
//        win.makeKeyAndVisible()
//        
//        window = win
//
////        #if targetEnvironment(macCatalyst)
////        if let titlebar = ws.titlebar {
////            let tb = NSToolbar(identifier: "MainToolbar")
////            tb.delegate = self
////            tb.allowsUserCustomization = false
////            titlebar.toolbar = tb
////            if #available(macCatalyst 14.0, *) { titlebar.toolbarStyle = .unifiedCompact }
////            titlebar.titleVisibility = .hidden
////        }
////        #endif
//    }
//
//#if targetEnvironment(macCatalyst)
////    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
////        return [.toggleSidebar, .flexibleSpace]
////    }
////    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
////        return [.toggleSidebar]
////    }
//    #endif
//
//    func sceneDidDisconnect(_ scene: UIScene) {
//        // Called as the scene is being released by the system.
//        // This occurs shortly after the scene enters the background, or when its session is discarded.
//        // Release any resources associated with this scene that can be re-created the next time the scene connects.
//        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
//    }
//
//    func sceneDidBecomeActive(_ scene: UIScene) {
//        // Called when the scene has moved from an inactive state to an active state.
//        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
//    }
//
//    func sceneWillResignActive(_ scene: UIScene) {
//        // Called when the scene will move from an active state to an inactive state.
//        // This may occur due to temporary interruptions (ex. an incoming phone call).
//    }
//
//    func sceneWillEnterForeground(_ scene: UIScene) {
//        // Called as the scene transitions from the background to the foreground.
//        // Use this method to undo the changes made on entering the background.
//    }
//
//    func sceneDidEnterBackground(_ scene: UIScene) {
//        // Called as the scene transitions from the foreground to the background.
//        // Use this method to save data, release shared resources, and store enough scene-specific state information
//        // to restore the scene back to its current state.
//    }
//
//
//}

public class UINSWindow: UIWindow {
    public var nsWindow: Dynamic?
    
    public let config: NSWindowConfig
    
    public var toolbarInsets: UIEdgeInsets {
        super.safeAreaInsets
    }
    
    public override var safeAreaInsets: UIEdgeInsets {
        .init(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    public init(windowScene: UIWindowScene, config: NSWindowConfig) {
        self.config = config
        super.init(windowScene: windowScene)
    }
    
    public override func makeKeyAndVisible() {
        makeKeyAndVisible(completion: nil)
    }
    
    public func makeKeyAndVisible(completion: ((Dynamic) -> Void)?) {
        super.makeKeyAndVisible()
        guard let windowScene else { return }
        config.awaitOpeningApply(window: self, scene: windowScene) {[weak self] in
            self?.nsWindow = $0
            completion?($0)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MyWindow: UIWindow {
    override var safeAreaInsets: UIEdgeInsets {.zero}
}

class Mv: UIView {
    override var safeAreaInsets: UIEdgeInsets {
        var ins = super.safeAreaInsets
        ins.left += 80
        return ins
//        .init(top: 0, left: 80, bottom: 0, right: 0)
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let ws = scene as? UIWindowScene else { return }
//        window = MyWindow(windowScene: ws)
        
        let window = UINSWindow(
            windowScene: ws,
            config: .init()
//                .color(.clear)
//                .isOpaque(false)
                .styleMask([.fullSizeContentView, .titled, .closable, .miniaturizable, .resizable])
                .titleVisibility(.hidden)
                .transparentTitlebar(true)
        )

        
        let tb = NSToolbar(identifier: "Tb")
        ws.titlebar?.toolbarStyle = .unified
        ws.titlebar?.titleVisibility = .hidden
        ws.titlebar?.toolbar = tb
        
//        tb.delegate = self
        // 3-колоночный сплит как в Xcode
        let split = UISplitViewController(style: .tripleColumn)
        split.primaryEdge = .trailing

        // Три корневых контроллера
        let b = SidebarViewController()
        let sidebar      =  UINavigationController(rootViewController:b)
        
//        sidebar.pushViewController(InspectorViewController(), animated: false)
        let editorCenter = UINavigationController(rootViewController: EditorViewController())
        
        let aa = InspectorViewController()
        let inspector    = UINavigationController(rootViewController: aa)
        
        let addItem = UIBarButtonItem(barButtonSystemItem: .add,
                                      target: self,
                                      action: #selector(addTapped))
        
        let refresh = UIBarButtonItem(barButtonSystemItem: .add,
                                      target: self,
                                      action: #selector(addTapped))
        let flex     = UIBarButtonItem(barButtonSystemItem: .camera,
                                       target: self,
                                       action: #selector(addTapped))
        let trash    = UIBarButtonItem(barButtonSystemItem: .bookmarks,
                                       target: self,
                                       action: #selector(addTapped))
        
        let space    = UIBarButtonItem(systemItem: .flexibleSpace)

//        b.toolbarItems = [refresh, flex, trash]
//        editorCenter.setToolbarHidden(false, animated: false)
//        aa.navigationItem.rightBarButtonItem = addItem
//        let share = UIBarButtonItem(systemItem: .action, primaryAction: UIAction { _ in /* ... */ })
        let a = addItem.creatingMovableGroup(customizationIdentifier: "test")
//        a.barButtonItems = [refresh, flex]
        
        sidebar.navigationBar.preferredBehavioralStyle = .pad
        b.navigationItem.style = .browser
        b.navigationItem.centerItemGroups = [
            .movableGroup(customizationIdentifier: "etest", items: [refresh, space, flex]),
            .movableGroup(customizationIdentifier: "etest1", items: [addItem])
        ]
        
        inspector.navigationBar.preferredBehavioralStyle = .pad
//        sidebar.additionalSafeAreaInsets = .init(top: 0, left: 200, bottom: 0, right: 0)
       
        let testa = Mv()
        testa.frame.size.width = window.frame.width
        testa.frame.size.height = 50
//        testa.backgroundColor = .red
        testa.addSubview(sidebar.navigationBar)
        sidebar.view.addSubview(testa)
        
//        sidebar.navigationItem.rightBarButtonItems = [refresh, flex, trash]
//        inspector.pushViewController(InspectorViewController(), animated: false)
        
//        split
        split.preferredSplitBehavior = .tile
        split.preferredDisplayMode = .oneBesideSecondary
        split.primaryBackgroundStyle = .sidebar
        
//        split.presentsWithGesture = false
        
//        split.set
        // Привязываем к колонкам слева -> центр -> справа
        
        split.setViewController(sidebar,      for: .secondary)        // левое «меню»
//        split.setViewController(editorCenter, for: .supplementary)  // центральное окно
       
        split.setViewController(inspector,    for: .supplementary)
   
        
//        split.setViewController(inspector,      for: .compact)
//        split.viewControllers = [sidebar, editorCenter, inspector]
//        let v = UIView()
//        v.frame.size.width = 10
//        v.frame.size.height = 10
//        v.backgroundColor = .white
//       
//        
        window.rootViewController = split
        self.window = window
        
        Task {
//            try await Task.sleep(for: .seconds(2))
//            split.hide(.primary)
//            try await Task.sleep(for: .seconds(3))
//            split.show(.primary)
//            
//            try await Task.sleep(for: .seconds(1))
//            split.hide(.secondary)
//            try await Task.sleep(for: .seconds(3))
//            split.show(.secondary)
//            
//            try await Task.sleep(for: .seconds(1))
//            split.hide(.supplementary)
//            try await Task.sleep(for: .seconds(3))
//            split.show(.supplementary)
//            
//            if #available(macCatalyst 26.0, *) {
//                try await Task.sleep(for: .seconds(1))
//                split.hide(.inspector)
//                try await Task.sleep(for: .seconds(3))
//                split.show(.inspector)
//            }
//            
           
        }
        window.makeKeyAndVisible()
    }
    
    @objc
    func addTapped() {
        
    }

}


final class SidebarViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Навигатор"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int { 20 }
    override func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let c = tv.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        c.textLabel?.text = "Элемент \(indexPath.row)"
        return c
    }
}

final class EditorViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Редактор"
        let label = UILabel()
        label.text = "Центральная область"
        label.font = .preferredFont(forTextStyle: .title2)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

final class InspectorViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        
        let iv = UIImageView(image: UIImage(resource: .frame2043682845))
        iv.contentMode = .scaleAspectFill
        iv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(iv)
//        title = "Инспектор"
    }
}

struct SidebarItem: Hashable {
    let id = UUID()
    let title: String
    let symbol: String
}

