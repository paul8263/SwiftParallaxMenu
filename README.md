# Parallax Slide Menu

## Introduction

Left or Right slide menu with parallax effect.

## How to Use & Config

In AppDelegate.swift:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        setupParallexMenuViewController()
        return true
}

private func setupParallexMenuViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainViewController = storyboard.instantiateViewController(withIdentifier: "mainViewController") as! MainViewController
        let leftMenuViewController = storyboard.instantiateViewController(withIdentifier: "leftMenuTableViewController") as! LeftMenuTableViewController
        let rightMenuViewController = storyboard.instantiateViewController(withIdentifier: "rightMenuTableViewController")
        let menuViewController = PLParallaxViewController(withMainViewController: mainViewController, leftMenuViewController: leftMenuViewController, rightMenuViewController: rightMenuViewController)
        // Configuration
        menuViewController.configBackground(withImage: UIImage(named: "backgroundImage")!)
        menuViewController.configRightSlideMenu(withOffsetY: 200, width: 150)
        menuViewController.configLeftSlideMenu(withOffsetY: 200, width: 150)
        menuViewController.configMainViewZoomedOffsetXWithSlideMenuShown(offsetX: 150)
        
        menuViewController.configLeftMenuGestureEnabled(enabled: true)
        menuViewController.configRightMenuGestureEnabled(enabled: true)
        
        window?.rootViewController = menuViewController
        window?.makeKeyAndVisible()
}
```



## Author

Paul Zhang