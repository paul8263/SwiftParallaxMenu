//
//  PLParallaxMainViewController.swift
//  PLParallaxSlideMenu
//
//  Created by Paul Zhang on 27/12/2016.
//  Copyright © 2016 Paul Zhang. All rights reserved.
//

import UIKit

enum SlideMenuStatus {
    case bothClosed
    case leftOpened
    case rightOpened
}

extension UIViewController {
    var parallaxViewController: PLParallaxViewController? {
        get {
            return getParallaxViewController()
        }
    }
    
    fileprivate func getParallaxViewController() -> PLParallaxViewController? {
        if let parentViewController = parent {
            if parentViewController is PLParallaxViewController {
                return parentViewController as? PLParallaxViewController
            } else {
                return nil
            }
        }
        return nil
    }
    
    func showLeftMenu() {
        parallaxViewController?.showLeftMenuViewController()
    }
    
    func showRightMenu() {
        parallaxViewController?.showRightMenuViewController()
    }
    
    func showMainView() {
        parallaxViewController?.showMainViewController()
    }
}

class PLParallaxViewController: UIViewController {
    
    private(set) var slideMenuStatus: SlideMenuStatus = .bothClosed
    
    private(set) var leftSlideMenuOffsetY = CGFloat(100)
    
    private(set) var leftSlideMenuWidth = CGFloat(200)
    
    private(set) var rightSlideMenuOffsetY = CGFloat(100)
    
    private(set) var rightSlideMenuWidth = CGFloat(200)
    
    private(set) var mainViewZoomedOffsetXWithLeftMenuShown = CGFloat(100)
    
    private(set) var mainViewZoomedOffsetXWithRightMenuShown = CGFloat(100)
    
    private(set) var mainViewZoomedOffsetX = CGFloat(100) {
        didSet {
            mainViewZoomedOffsetXWithLeftMenuShown = mainViewZoomedOffsetX
            mainViewZoomedOffsetXWithRightMenuShown = mainViewZoomedOffsetX
        }
    }
    
    private(set) var showMenuAnimationDuration = 0.5
    
    var leftMenuViewController: UIViewController? {
        willSet {
            if let vc = newValue {
                setupViewController(toContainerView: leftMenuContainerView, viewController: vc)
            }
        }
        didSet {
            setupLeftMenuContainerView()
        }
    }
    
    var rightMenuViewController: UIViewController? {
        willSet {
            if let vc = newValue {
                setupViewController(toContainerView: rightMenuContainerView, viewController: vc)
            }
        }
        didSet {
            setupRightMenuContainerView()
        }
    }
    
    var mainViewController: UIViewController! {
        willSet {
            setupViewController(toContainerView: mainViewControllerContainerView, viewController: newValue)
        }
        didSet {
            setupMainViewContainerView()
        }
    }
    
    private(set) var backgroundImage: UIImage?
    
    private let mainViewControllerContainerView = UIView()
    
    private let backgroundImageContainerView = UIView()
    
    private let backgroundImageView = UIImageView()
    
    private let leftMenuContainerView = UIView()
    
    private let rightMenuContainerView = UIView()
    
    func setBackground(withImage image: UIImage) {
        backgroundImage = image
    }
    
    private func setupViewController(toContainerView containerView: UIView, viewController: UIViewController) {
        addChildViewController(viewController)
        viewController.didMove(toParentViewController: self)
        containerView.addSubview(viewController.view)
        viewController.view.didMoveToSuperview()
    }
    
    private func setupMainViewContainerView() {
        view.addSubview(mainViewControllerContainerView)
        mainViewControllerContainerView.frame = view.frame
        mainViewController.view.frame = view.frame
    }
    
    private func setupBackgroundImageView() {
        view.insertSubview(backgroundImageContainerView, at: 0)
        backgroundImageContainerView.frame = view.frame
        backgroundImageContainerView.backgroundColor = UIColor.gray
        
        backgroundImageContainerView.addSubview(backgroundImageView)
        backgroundImageView.frame = view.frame
        backgroundImageView.contentMode = .scaleToFill
        if let image = backgroundImage {
            backgroundImageView.image = image
        }
    }
    
    private func setupLeftMenuContainerView() {
        view.addSubview(leftMenuContainerView)
        leftMenuContainerView.frame = CGRect(x: view.frame.origin.x, y: view.frame.origin.y + leftSlideMenuOffsetY, width: leftSlideMenuWidth, height: view.frame.height - 2 * leftSlideMenuOffsetY)
        leftMenuViewController?.view.frame = leftMenuContainerView.bounds
        leftMenuViewController?.view.backgroundColor = UIColor.clear
    }
    
    private func setupRightMenuContainerView() {
        view.addSubview(rightMenuContainerView)
        rightMenuContainerView.frame = CGRect(x: view.frame.width - rightSlideMenuWidth , y: view.frame.origin.y + rightSlideMenuOffsetY, width: rightSlideMenuWidth, height: view.frame.height - 2 * leftSlideMenuOffsetY)
        rightMenuViewController?.view.frame = leftMenuContainerView.bounds
        rightMenuViewController?.view.backgroundColor = UIColor.clear
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(withMainViewController mainViewController: UIViewController, leftMenuViewController: UIViewController?, rightMenuViewController: UIViewController?) {
        self.init()
        self.mainViewController = mainViewController
        self.leftMenuViewController = leftMenuViewController
        self.rightMenuViewController = rightMenuViewController
    }
    
    fileprivate func showLeftMenuViewController() {
        if leftMenuViewController == nil {
            return
        }
        showMenuViewController(toSlideMenuStatus: .leftOpened)
    }
    
    fileprivate func showRightMenuViewController() {
        if rightMenuViewController == nil {
            return
        }
        showMenuViewController(toSlideMenuStatus: .rightOpened)
    }
    
    private func showMenuViewController(toSlideMenuStatus: SlideMenuStatus) {
        if toSlideMenuStatus == .bothClosed {
            fatalError("You cannot set toSlideMenuStatus to bothClosed in function showMenuViewController:toSlideMenuStatus")
        }
        slideMenuStatus = toSlideMenuStatus
        rightMenuContainerView.isHidden = toSlideMenuStatus == .leftOpened
        leftMenuContainerView.isHidden = toSlideMenuStatus == .rightOpened
        leftMenuContainerView.alpha = 0
        rightMenuContainerView.alpha = 0
        let snapshot = mainViewControllerContainerView.snapshotView(afterScreenUpdates: false)!
        snapshot.tag = 999
        mainViewControllerContainerView.addSubview(snapshot)
        mainViewController?.view.removeFromSuperview()
        
        backgroundImageContainerView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        
        UIView.animate(withDuration: showMenuAnimationDuration) {
            self.mainViewControllerContainerView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            if toSlideMenuStatus == .leftOpened {
                self.mainViewControllerContainerView.frame.origin.x += self.mainViewZoomedOffsetXWithLeftMenuShown
            } else if toSlideMenuStatus == .rightOpened {
                self.mainViewControllerContainerView.frame.origin.x -= self.mainViewZoomedOffsetXWithRightMenuShown
            }
            
            self.setNeedsStatusBarAppearanceUpdate()
            
            if toSlideMenuStatus == .leftOpened {
                self.leftMenuContainerView.alpha = 1
            } else if toSlideMenuStatus == .rightOpened {
                self.rightMenuContainerView.alpha = 1
            }
            self.backgroundImageContainerView.transform = CGAffineTransform.identity
        }
    }
    
    fileprivate func showMainViewController() {
        switch slideMenuStatus {
        case .bothClosed:
            return
        case .leftOpened:
            showMainViewController(fromStatus: .leftOpened)
        case .rightOpened:
            showMainViewController(fromStatus: .rightOpened)
        }
    }
    
    private func showMainViewController(fromStatus: SlideMenuStatus) {
        if fromStatus == .bothClosed {
            fatalError("You cannot set from status with bothClosed in method showMainViewController:fromStatus")
        }
        slideMenuStatus = .bothClosed
        UIView.animate(withDuration: showMenuAnimationDuration, animations: {
            self.mainViewControllerContainerView.transform = CGAffineTransform.identity
            self.mainViewControllerContainerView.frame = self.view.frame
            self.setNeedsStatusBarAppearanceUpdate()
            if fromStatus == .leftOpened {
                self.leftMenuContainerView.alpha = 0
            } else if fromStatus == .rightOpened {
                self.rightMenuContainerView.alpha = 0
            }
            self.backgroundImageContainerView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            
        }) { (finished) in
            self.mainViewControllerContainerView.addSubview(self.mainViewController.view)
            self.mainViewController.view.frame = self.view.frame
            self.mainViewControllerContainerView.viewWithTag(999)?.removeFromSuperview()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        switch slideMenuStatus {
        case .bothClosed:
            return .default
        case .leftOpened:
            return .lightContent
        case .rightOpened:
            return .lightContent
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViewController(toContainerView: mainViewControllerContainerView, viewController: mainViewController)
        if let leftVC = leftMenuViewController {
            setupViewController(toContainerView: leftMenuContainerView, viewController: leftVC)
            setupLeftMenuContainerView()
        }
        if let rightVC = rightMenuViewController {
            setupViewController(toContainerView: rightMenuContainerView, viewController: rightVC)
            setupRightMenuContainerView()
        }
        
        setupMainViewContainerView()
        setupBackgroundImageView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
