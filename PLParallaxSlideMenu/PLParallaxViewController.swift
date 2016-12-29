//
//  PLParallaxMainViewController.swift
//  PLParallaxSlideMenu
//
//  Created by Paul Zhang on 27/12/2016.
//  Copyright © 2016 Paul Zhang. All rights reserved.
//

import UIKit
/**
 The status of PLParallaxViewController, indicating which slide menu is open or both are closed
 */
enum SlideMenuStatus {
    /**
     Indicating both left and right menu are closed
     */
    case bothClosed
    /**
     Indicating left slide menu is open
     */
    case leftOpened
    /**
     Indicating right slided menu is open
     */
    case rightOpened
}

extension UIViewController {
    /**
    Get the parent parallax view controller
     
    @return parallaxViewController if the parent view controller is PLParallaxController or nil if the parent view controller is not PLParallaxViewController
     */
    var parallaxViewController: PLParallaxViewController? {
        get {
            return getParallaxViewController()
        }
    }
    
    /**
     Private method for retrieving the parent parallax view controller
     */
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
    
    /**
     Show left slide menu. Only take effect when current status is .bothClosed
     */
    func showLeftMenu() {
        parallaxViewController?.showLeftMenuViewController()
    }
    
    /**
     Show right slide menu. Only take effect when current status is .bothClosed
     */
    func showRightMenu() {
        parallaxViewController?.showRightMenuViewController()
    }
    
    /**
     Close slide menu. Only take effect when current status is .leftOpened or .rightOpened
     */
    func showMainView() {
        parallaxViewController?.showMainViewController()
    }
}

public class PLParallaxViewController: UIViewController {
    /**
     The status of PLParallaxViewController, indicating which slide menu is open or both are closed
    */
    private(set) var slideMenuStatus: SlideMenuStatus = .bothClosed {
        didSet {
            switch slideMenuStatus {
            case .bothClosed:
                enableScreenEdgeGestureRecognizer()
                disableCloseMenuPanGestureRecognizer()
            case .leftOpened:
                disableScreenEdgeGestureRecognizer()
                enableCloseLeftMenuPanGestureRecognizer()
            case .rightOpened:
                disableCloseMenuPanGestureRecognizer()
                enableCloseRightMenuPanGestureRecognizer()
            }
        }
    }
    /**
     Helper status for determine the status bar style
     */
    private var willTransitionToStatus: SlideMenuStatus = .bothClosed
    
    /**
     The Y axis offset from the screen top to the top side of the left slide menu
    */
    private(set) var leftSlideMenuOffsetY = CGFloat(100)
    
    /**
     The width for the left slide menu
     */
    private(set) var leftSlideMenuWidth = CGFloat(200)
    
    /**
     The Y axis offset from the screen top to the top slde of the right slide menu
     */
    private(set) var rightSlideMenuOffsetY = CGFloat(100)
    
    /**
     The width for the right slide menu
     */
    private(set) var rightSlideMenuWidth = CGFloat(200)
    
    /**
     The Y axis offset from the screen top to the top side of the left slide menu, when the device is in landscape orientation
     */
    private(set) var leftSlideMenuOffsetYLandscape = CGFloat(40)
    
    /**
     The Y axis offset from the screen top to the top slde of the right slide menu, when the device is in landscape orientation
     */
    private(set) var rightSlideMenuOffsetYLandscape = CGFloat(40)
    
    /**
     Defines the x offset of the zoomed main menu when the left slide menu is shown
     */
    private(set) var mainViewZoomedOffsetXWithLeftMenuShown = CGFloat(100)
    
    /**
     Defines the x offset of the zoomed main menu when the right slide menu is shown
     */
    private(set) var mainViewZoomedOffsetXWithRightMenuShown = CGFloat(100)
    
    /**
     Defined the x offset of the zoomed main menu when either left or right slide menu is shown
     */
    private(set) var mainViewZoomedOffsetX = CGFloat(100) {
        didSet {
            mainViewZoomedOffsetXWithLeftMenuShown = mainViewZoomedOffsetX
            mainViewZoomedOffsetXWithRightMenuShown = mainViewZoomedOffsetX
        }
    }
    
    /**
     Defines the show or hide slide menu animation duration
     */
    private(set) var showMenuAnimationDuration = 0.5
    
    /**
     Defines the zoom scale for the background image before the slide menu is shown
     */
    private(set) var backgroundImageViewZoomScale: CGFloat = 1.3
    
    /**
     Defines the zoom scale for the main menu view when either slide menu is shown
     */
    private(set) var mainViewZoomScale: CGFloat = 0.5
    
    /**
     The CGAffineTransform for the background iamge view
     */
    private var backgroundImageViewTransform: CGAffineTransform {
        return CGAffineTransform(scaleX: backgroundImageViewZoomScale, y: backgroundImageViewZoomScale)
    }
    
    /**
     The CGAffineTransform for the main view controller
     */
    private var mainViewTransform: CGAffineTransform {
        return CGAffineTransform(scaleX: mainViewZoomScale, y: mainViewZoomScale)
    }
    
    /**
     Preferred status bar style when main menu is shown
     */
    private(set) var preferredStatusBarStyleForMainMenu: UIStatusBarStyle = .default
    
    /**
     Preferred status bar style when slide menu is shown
     */
    private(set) var preferredStatusBarStyleForSlideMenu: UIStatusBarStyle = .lightContent
    
    /**
     Left menu view controller
     */
    var leftMenuViewController: UIViewController? {
        willSet {
            if let vc = newValue {
                setup(viewController: vc, toContainerView: leftMenuContainerView)
            }
        }
        didSet {
            setupLeftMenuContainerView()
        }
    }
    
    /**
     Right menu view controller
     */
    var rightMenuViewController: UIViewController? {
        willSet {
            if let vc = newValue {
                setup(viewController: vc, toContainerView: rightMenuContainerView)
            }
        }
        didSet {
            setupRightMenuContainerView()
        }
    }
    
    /**
     Main view controller
     */
    private(set) var mainViewController: UIViewController! {
        willSet {
            setup(viewController: newValue, toContainerView: mainViewControllerContainerView)
        }
        didSet {
            setupMainViewContainerView()
        }
    }
    
    /**
     Background image displayed when either slide menu is shown
     */
    private(set) var backgroundImage: UIImage?
    
    private lazy var backgroundImageRotatedLeft: UIImage = {
       return self.rotateImage(image: #imageLiteral(resourceName: "backgroundImage"), toOrientation: .left)
    }()
    
    private lazy var backgroundImageRotatedRight: UIImage = {
        return self.rotateImage(image: #imageLiteral(resourceName: "backgroundImage"), toOrientation: .right)
    }()
    
    /**
     Determines whether the open left screen edge pan gesture is enabled
     */
    private(set) var isLeftScreenEdgePanGestureEnabled = false {
        willSet {
            if newValue && leftMenuViewController != nil {
                setupScreenEdgePanGesture(fromScreenEdge: .left)
                setupCloseLeftMenuPanGesture()
            } else {
                leftScreenEdgePanGestureRecognizer = nil
                closeLeftMenuPanGestureRecognizer = nil
            }
        }
    }
    
    /**
     Determines whether the open right screen edge pan gesture is enabled
     */
    private(set) var isRightScreenEdgePanGestureEnabled = false {
        willSet {
            if newValue && rightMenuViewController != nil {
                setupScreenEdgePanGesture(fromScreenEdge: .right)
                setupCloseRightMenuPanGesture()
            } else {
                rightScreenEdgePanGestureRecognizer = nil
                closeRightMenuPanGestureRecognizer = nil
            }
        }
    }
    
    /**
     Defined snapshot view tag
     */
    let snapshotViewTag = 999
    
    /**
     Defined pan gesture success threshold
     */
    let panGestureSuccessPercent: CGFloat = 0.3
    
//    Container views
    
    private let mainViewControllerContainerView = UIView()
    
    private let backgroundImageContainerView = UIView()
    
    private let backgroundImageView = UIImageView()
    
    private let leftMenuContainerView = UIView()
    
    private let rightMenuContainerView = UIView()
    
//    Gesture recognizers
    
    var leftScreenEdgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer?
    
    var rightScreenEdgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer?
    
    var closeLeftMenuPanGestureRecognizer: UIPanGestureRecognizer?
    
    var closeRightMenuPanGestureRecognizer: UIPanGestureRecognizer?
    
//    ---------------------------------------------------
//    Configuration method
    
    /**
     Config background image
     
     - parameter withImage: background image with type UIImage
     */
    func configBackground(withImage image: UIImage) {
        backgroundImage = image
        backgroundImageView.image = backgroundImage
    }
    
    /**
     Config left slide menu
     
     - parameter withOffsetY: Y axis offset
     - parameter width: Menu width
     */
    func configLeftSlideMenu(withOffsetY offsetY: CGFloat, width: CGFloat) {
        leftSlideMenuOffsetY = offsetY
        leftSlideMenuWidth = width
        setupLeftMenuContainerView()
    }
    
    /**
     Config right slide menu
     
     - parameter withOffsetY: Y axis offset
     - parameter width: Menu width
     */
    func configRightSlideMenu(withOffsetY offsetY: CGFloat, width: CGFloat) {
        rightSlideMenuOffsetY = offsetY
        rightSlideMenuWidth = width
        setupRightMenuContainerView()
    }
    
    /**
     Config both left and right slide menu
     
     - parameter withOffsetY: Y axis offset
     - parameter width: Menu width
     */
    func configSlideMenu(withOffsetY offsetY: CGFloat, width: CGFloat) {
        configLeftSlideMenu(withOffsetY: offsetY, width: width)
        configRightSlideMenu(withOffsetY: offsetY, width: width)
    }
    
    /**
     Config left slide menu when device is landscape orientation
     
     - parameter withOffsetY: Y offset
     */
    func configLeftSlideMenuLandscape(withOffsetY offsetY: CGFloat) {
        leftSlideMenuOffsetYLandscape = offsetY
        setupLeftMenuContainerView()
    }
    
    /**
     Config right slide menu when device is landscape orientation
     
     - parameter withOffsetY: Y offset
     */
    func configRightSlideMenuLandscape(withOffsetY offsetY: CGFloat) {
        rightSlideMenuOffsetYLandscape = offsetY
        setupRightMenuContainerView()
    }
    
    /**
     Config main view offset X when left slide menu is shown
     
     - parameter offsetX: X axis offset
     */
    func configMainViewZoomedOffsetXWithLeftMenuShown(offsetX: CGFloat) {
        mainViewZoomedOffsetXWithLeftMenuShown = offsetX
    }
    
    /**
     Config main view offset X when right slide menu is shown
     
     - parameter offsetX: X axis offset
     */
    func configMainViewZoomedOffsetXWithRightMenuShown(offsetX: CGFloat) {
        mainViewZoomedOffsetXWithRightMenuShown = offsetX
    }
    
    /**
     Config main view offset X when either left or right slide menu is shown
     
     - parameter offsetX: X axis offset
     */
    func configMainViewZoomedOffsetXWithSlideMenuShown(offsetX: CGFloat) {
        configMainViewZoomedOffsetXWithLeftMenuShown(offsetX: offsetX)
        configMainViewZoomedOffsetXWithRightMenuShown(offsetX: offsetX)
    }
    
    /**
     Config background image view as the animation start status before the slide menu is shown
     
     - parameter scale: The initial scale. Should be equal or greater than 1
     */
    func configBackgroundImageViewZoomScale(scale: CGFloat) {
        if scale < 1 {
            print("Illegal value for background image view zoom scale")
        } else {
            backgroundImageViewZoomScale = scale
        }
    }
    
    /**
     Config the zoom scale for main menu when either slide menu is shown
     
     - parameter scale: Scale value. Should be between 0 and 1
     */
    func configMainMenuViewZoomScale(scale: CGFloat) {
        if scale < 0 || scale > 1 {
            print("Illegal value for main menu view zoom scale")
        } else {
            mainViewZoomScale = scale
        }
    }
    
    /**
     Config whether open and close left slide menu gesture is enabled
     
     - parameter enabled: Enable or disable the gesture
     */
    func configLeftMenuGestureEnabled(enabled: Bool) {
        isLeftScreenEdgePanGestureEnabled = enabled
    }
    
    /**
     Config whether open and close right slide menu gesture is enabled
     
     @param enabled: Enable or disable the gesture
     */
    func configRightMenuGestureEnabled(enabled: Bool) {
        isRightScreenEdgePanGestureEnabled = enabled
    }
    
    /**
     Config hide and show slide menu animation duration
     
     - parameter second: Animation duration in second
     */
    func configShowMenuAnimationDuration(second: Double) {
        showMenuAnimationDuration = second
    }
    
    /**
     Config preferred status bar style for main menu
     
     - parameter style: Statue bar style
     */
    func configPreferredStatusBarStyleForMainMenu(style: UIStatusBarStyle) {
        preferredStatusBarStyleForMainMenu = style
    }
    
    /**
     Config preferred status bar style for slide menu
     
     - parameter style: Statue bar style
     */
    func configPreferredStatusBarStyleForSlideMenu(style: UIStatusBarStyle) {
        preferredStatusBarStyleForSlideMenu = style
    }
    
//    ---------------------------------------------------
//    Setup Functions
    /**
     Add the view controller to container view
     
     - parameter viewController: View controller to setup
     - parameter toContainerView: Container view the view controller will be added to
     */
    private func setup(viewController: UIViewController, toContainerView containerView: UIView) {
        addChildViewController(viewController)
        viewController.didMove(toParentViewController: self)
        containerView.addSubview(viewController.view)
        viewController.view.didMoveToSuperview()
    }
    
    /**
     Setup main view container view
     */
    private func setupMainViewContainerView() {
        mainViewControllerContainerView.frame = view.frame
        mainViewController.view.frame = view.frame
        mainViewControllerContainerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        mainViewController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    /**
     Setup background image view
     */
    private func setupBackgroundImageView() {
        backgroundImageContainerView.frame = view.frame
        backgroundImageContainerView.backgroundColor = UIColor.gray
        
        backgroundImageView.frame = view.frame
        backgroundImageView.contentMode = .scaleToFill
        if let image = backgroundImage {
            switch UIApplication.shared.statusBarOrientation {
            case .portrait:
                backgroundImageView.image = image
            case .landscapeLeft:
                backgroundImageView.image = backgroundImageRotatedLeft
            case .landscapeRight:
                backgroundImageView.image = backgroundImageRotatedRight
            default:
                backgroundImageView.image = image
            }
        }
        
        backgroundImageContainerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        backgroundImageView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    /**
     Setup left menu container view
     */
    private func setupLeftMenuContainerView() {
        let frame: CGRect!
        if UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight {
            frame = CGRect(x: view.frame.origin.x, y: view.frame.origin.y + leftSlideMenuOffsetYLandscape, width: leftSlideMenuWidth, height: view.frame.height - 2 * leftSlideMenuOffsetYLandscape)
        } else {
            frame = CGRect(x: view.frame.origin.x, y: view.frame.origin.y + leftSlideMenuOffsetY, width: leftSlideMenuWidth, height: view.frame.height - 2 * leftSlideMenuOffsetY)
        }
        leftMenuContainerView.frame = frame
        leftMenuViewController?.view.frame = leftMenuContainerView.bounds
        leftMenuViewController?.view.backgroundColor = UIColor.clear
        leftMenuContainerView.isHidden = true
        
        leftMenuContainerView.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        leftMenuViewController?.view.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        
        if leftMenuViewController == nil {
            leftScreenEdgePanGestureRecognizer?.isEnabled = false
        }
    }
    
    /**
     Setup right menu container view
     */
    private func setupRightMenuContainerView() {
        let frame: CGRect!
        if UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight {
            frame = CGRect(x: view.frame.width - rightSlideMenuWidth , y: view.frame.origin.y + rightSlideMenuOffsetYLandscape, width: rightSlideMenuWidth, height: view.frame.height - 2 * rightSlideMenuOffsetYLandscape)
        } else {
            frame = CGRect(x: view.frame.width - rightSlideMenuWidth , y: view.frame.origin.y + rightSlideMenuOffsetY, width: rightSlideMenuWidth, height: view.frame.height - 2 * rightSlideMenuOffsetY)
        }
        rightMenuContainerView.frame = frame
        rightMenuViewController?.view.frame = rightMenuContainerView.bounds
        rightMenuViewController?.view.backgroundColor = UIColor.clear
        rightMenuContainerView.isHidden = true
        
        rightMenuContainerView.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
        rightMenuViewController?.view.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
        
        if rightMenuViewController == nil {
            rightScreenEdgePanGestureRecognizer?.isEnabled = false
        }
    }

//    ---------------------------------------------------
//    Init Methods
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /**
     Main constructor
     
     - parameter withMainViewController: Main view controller
     - parameter leftMenuViewController: Left menu view controller, or nil
     - parameter rightMenuViewController: Right menu view controller, or nil
     */
    convenience init(withMainViewController mainViewController: UIViewController, leftMenuViewController: UIViewController?, rightMenuViewController: UIViewController?) {
        self.init()
        self.mainViewController = mainViewController
        self.leftMenuViewController = leftMenuViewController
        self.rightMenuViewController = rightMenuViewController
    }
    
//    ---------------------------------------------------
//    Main Functions
    
    /**
     Show left menu view controller
     */
    fileprivate func showLeftMenuViewController() {
        if leftMenuViewController == nil {
            return
        }
        showMenuViewController(toSlideMenuStatus: .leftOpened)
    }
    
    /**
     Show right menu view controller
     */
    fileprivate func showRightMenuViewController() {
        if rightMenuViewController == nil {
            return
        }
        showMenuViewController(toSlideMenuStatus: .rightOpened)
    }
    
    /**
     Private function for showing the corresponding menu view controller
     
     - parameter toSlideMenuStatus: The target SlideMenuStatus to switch to
     */
    private func showMenuViewController(toSlideMenuStatus: SlideMenuStatus) {
        if toSlideMenuStatus == .bothClosed {
            fatalError("You cannot set toSlideMenuStatus to bothClosed in function showMenuViewController:toSlideMenuStatus")
        }
        
        willTransitionToStatus = toSlideMenuStatus
        
        rightMenuContainerView.isHidden = toSlideMenuStatus == .leftOpened
        leftMenuContainerView.isHidden = toSlideMenuStatus == .rightOpened
        leftMenuContainerView.alpha = 0
        rightMenuContainerView.alpha = 0
        let snapshot = mainViewControllerContainerView.snapshotView(afterScreenUpdates: false)!
        snapshot.tag = snapshotViewTag
        mainViewControllerContainerView.addSubview(snapshot)
        mainViewController?.view.removeFromSuperview()
        
        backgroundImageContainerView.transform = backgroundImageViewTransform
        
        UIView.animate(withDuration: showMenuAnimationDuration, animations: {
            self.mainViewControllerContainerView.transform = self.mainViewTransform
            let mainViewOriginX = self.mainViewControllerContainerView.frame.origin.x
            if toSlideMenuStatus == .leftOpened {
                self.mainViewControllerContainerView.frame.origin.x = mainViewOriginX + self.mainViewZoomedOffsetXWithLeftMenuShown
            } else if toSlideMenuStatus == .rightOpened {
                self.mainViewControllerContainerView.frame.origin.x = mainViewOriginX - self.mainViewZoomedOffsetXWithRightMenuShown
            }
            
            self.setNeedsStatusBarAppearanceUpdate()
            
            if toSlideMenuStatus == .leftOpened {
                self.leftMenuContainerView.alpha = 1
            } else if toSlideMenuStatus == .rightOpened {
                self.rightMenuContainerView.alpha = 1
            }
            self.backgroundImageContainerView.transform = CGAffineTransform.identity
        }) { (finished) in
            self.slideMenuStatus = toSlideMenuStatus
        }
    }
    
    /**
     Private method for view controller showing animation with percent. Used by pan gestures.
     
     - parameter toSlideMenuStatus: The target SlideMenuStatus to switch to
     - parameter withPercent: Current animation completion percent
     */
    private func showMenuViewControllerAnimating(toSlideMenuStatus: SlideMenuStatus, withPercent percent: CGFloat) {
        if toSlideMenuStatus == .bothClosed {
            fatalError("You cannot set toSlideMenuStatus to bothClosed in function showMenuViewControllerAnimating:toSlideMenuStatus:withPercent")
        }
        if percent < 0 || percent > 1 {
            fatalError("Illegal argument for percent in function showMenuViewController:toSlideMenuStatus:withPercent")
        }
        willTransitionToStatus = toSlideMenuStatus
        
        rightMenuContainerView.isHidden = toSlideMenuStatus == .leftOpened
        leftMenuContainerView.isHidden = toSlideMenuStatus == .rightOpened
        leftMenuContainerView.alpha = 0
        rightMenuContainerView.alpha = 0
        
        backgroundImageContainerView.transform = backgroundImageViewTransform
        
        let mainMenuZoomScaleWithPercent = 1 - (1 - mainViewZoomScale) * percent
        
        let backgroundImageZoomScaleWithPercent = backgroundImageViewZoomScale - (backgroundImageViewZoomScale - 1) * percent

        let baseMainViewOriginX = view.bounds.width * (1 - mainViewZoomScale) / 2
        
        self.mainViewControllerContainerView.transform = CGAffineTransform(scaleX: mainMenuZoomScaleWithPercent, y: mainMenuZoomScaleWithPercent)
        if toSlideMenuStatus == .leftOpened {
            self.mainViewControllerContainerView.frame.origin.x = (baseMainViewOriginX + self.mainViewZoomedOffsetXWithLeftMenuShown) * percent
        } else if toSlideMenuStatus == .rightOpened {
            self.mainViewControllerContainerView.frame.origin.x = (baseMainViewOriginX - self.mainViewZoomedOffsetXWithRightMenuShown) * percent
        }
            
        if toSlideMenuStatus == .leftOpened {
            self.leftMenuContainerView.alpha = percent
        } else if toSlideMenuStatus == .rightOpened {
            self.rightMenuContainerView.alpha = percent
        }
        self.backgroundImageContainerView.transform = CGAffineTransform(scaleX: backgroundImageZoomScaleWithPercent, y: backgroundImageZoomScaleWithPercent)
    }
    
    /**
     Private method for finishing view controller showing animation. Used by pan gestures.
     
     - parameter toSlideMenuStatus: The target SlideMenuStatus to switch to
     - parameter shouldComplete: True if the showing animation needs to be complete. If false, the animation will return to its initial state
     */
    private func finishShowMenuViewCntrollerAnimating(toSlideMenuStatus: SlideMenuStatus, shouldComplete: Bool) {
        if toSlideMenuStatus == .bothClosed {
            fatalError("You cannot set toSlideMenuStatus to bothClosed in function finishShowMenuViewControllerAnimating:toSlideMenuStatus:shouldComplete")
        }
        
        let finishingAnimationDuration = 0.2
        
        if shouldComplete {
            let baseMainViewOriginX = view.bounds.width * (1 - mainViewZoomScale) / 2
            UIView.animate(withDuration: finishingAnimationDuration, animations: {
                self.mainViewControllerContainerView.transform = self.mainViewTransform
                if toSlideMenuStatus == .leftOpened {
                    self.mainViewControllerContainerView.frame.origin.x = baseMainViewOriginX + self.mainViewZoomedOffsetXWithLeftMenuShown
                } else if toSlideMenuStatus == .rightOpened {
                    self.mainViewControllerContainerView.frame.origin.x = baseMainViewOriginX - self.mainViewZoomedOffsetXWithRightMenuShown
                }
                self.setNeedsStatusBarAppearanceUpdate()
                if toSlideMenuStatus == .leftOpened {
                    self.leftMenuContainerView.alpha = 1
                } else if toSlideMenuStatus == .rightOpened {
                    self.rightMenuContainerView.alpha = 1
                }
                self.backgroundImageContainerView.transform = CGAffineTransform.identity
            }, completion: {(finished) in
                self.slideMenuStatus = toSlideMenuStatus
            })
        } else {
            showMainViewController(fromStatus: toSlideMenuStatus)
        }
    }
    
    /**
     Show main view controller
     */
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
    
    /**
     Private function for howing main view controller
     
     - parameter fromStatus: From which status the animation will start
     */
    private func showMainViewController(fromStatus: SlideMenuStatus) {
        if fromStatus == .bothClosed {
            fatalError("You cannot set from status with bothClosed in method showMainViewController:fromStatus")
        }
        
        willTransitionToStatus = .bothClosed
        
        UIView.animate(withDuration: showMenuAnimationDuration, animations: {
            self.mainViewControllerContainerView.transform = CGAffineTransform.identity
            self.mainViewControllerContainerView.frame = self.view.frame
            self.setNeedsStatusBarAppearanceUpdate()
            if fromStatus == .leftOpened {
                self.leftMenuContainerView.alpha = 0
            } else if fromStatus == .rightOpened {
                self.rightMenuContainerView.alpha = 0
            }
            self.backgroundImageContainerView.transform = self.backgroundImageViewTransform
            
        }) { (finished) in
            self.mainViewControllerContainerView.addSubview(self.mainViewController.view)
            self.mainViewController.view.frame = self.view.frame
            self.mainViewControllerContainerView.viewWithTag(self.snapshotViewTag)?.removeFromSuperview()
            
            self.backgroundImageContainerView.transform = CGAffineTransform.identity
            
            self.slideMenuStatus = .bothClosed
        }
    }
    /**
     Setup screen edge pan gesture
     
     - parameter fromScreenEdge: Left edge pan gesture or right
     */
    private func setupScreenEdgePanGesture(fromScreenEdge: UIRectEdge) {
        let screenEdgePanGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgePanGestureTriggered(gesture:)))
        screenEdgePanGesture.edges = fromScreenEdge
        view.addGestureRecognizer(screenEdgePanGesture)
        if fromScreenEdge == .left {
            leftScreenEdgePanGestureRecognizer = screenEdgePanGesture
        } else if fromScreenEdge == .right {
            rightScreenEdgePanGestureRecognizer = screenEdgePanGesture
        }
    }
    
    /**
     Enable both left and right screen edge gesture recognisers
     */
    private func enableScreenEdgeGestureRecognizer() {
        leftScreenEdgePanGestureRecognizer?.isEnabled = true
        rightScreenEdgePanGestureRecognizer?.isEnabled = true
    }
    
    /**
     Disable both left and right screen edge gesture recognisers
     */
    private func disableScreenEdgeGestureRecognizer() {
        leftScreenEdgePanGestureRecognizer?.isEnabled = false
        rightScreenEdgePanGestureRecognizer?.isEnabled = false
    }
    
    /**
     Enable close left menu pan gesture recogniser
     */
    private func enableCloseLeftMenuPanGestureRecognizer() {
        closeLeftMenuPanGestureRecognizer?.isEnabled = true
    }
    
    /**
     Enable close right menu pan gesture recogniser
     */
    private func enableCloseRightMenuPanGestureRecognizer() {
        closeRightMenuPanGestureRecognizer?.isEnabled = true
    }
    
    /**
     Disable close both left and right menu pan gesture recognisers
     */
    private func disableCloseMenuPanGestureRecognizer() {
        closeLeftMenuPanGestureRecognizer?.isEnabled = false
        closeRightMenuPanGestureRecognizer?.isEnabled = false
    }
    
    func screenEdgePanGestureTriggered(gesture: UIScreenEdgePanGestureRecognizer) {
        let percent = fabs(gesture.translation(in: view).x) / view.bounds.size.width
        if gesture.edges == .left {
            switch gesture.state {
            case .began:
                let snapshot = mainViewControllerContainerView.snapshotView(afterScreenUpdates: false)!
                snapshot.tag = snapshotViewTag
                mainViewControllerContainerView.addSubview(snapshot)
                mainViewController?.view.removeFromSuperview()
            case .changed:
                showMenuViewControllerAnimating(toSlideMenuStatus: .leftOpened, withPercent: percent)
            case .ended:
                finishShowMenuViewCntrollerAnimating(toSlideMenuStatus: .leftOpened, shouldComplete: percent >= self.panGestureSuccessPercent)
            default:
                finishShowMenuViewCntrollerAnimating(toSlideMenuStatus: .leftOpened, shouldComplete: percent >= self.panGestureSuccessPercent)
            }
        } else if gesture.edges == .right {
            switch gesture.state {
            case .began:
                let snapshot = mainViewControllerContainerView.snapshotView(afterScreenUpdates: false)!
                snapshot.tag = snapshotViewTag
                mainViewControllerContainerView.addSubview(snapshot)
                mainViewController?.view.removeFromSuperview()
            case .changed:
                showMenuViewControllerAnimating(toSlideMenuStatus: .rightOpened, withPercent: percent)
            case .ended:
                finishShowMenuViewCntrollerAnimating(toSlideMenuStatus: .rightOpened, shouldComplete: percent >= self.panGestureSuccessPercent)
            default:
                finishShowMenuViewCntrollerAnimating(toSlideMenuStatus: .rightOpened, shouldComplete: percent >= self.panGestureSuccessPercent)
            }
        }
    }
    
    /**
     Setup close left menu pan gesture
     */
    private func setupCloseLeftMenuPanGesture() {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(closeLeftMenuPanGestureTriggered(gesture:)))
        self.closeLeftMenuPanGestureRecognizer = gesture
        gesture.isEnabled = false
        gesture.delegate = self
        view.addGestureRecognizer(gesture)
    }
    
    func closeLeftMenuPanGestureTriggered(gesture: UIPanGestureRecognizer) {
        let percent = fabs(gesture.translation(in: view).x) / view.bounds.size.width
        switch gesture.state {
        case .began:
            break
        case .changed:
            showMenuViewControllerAnimating(toSlideMenuStatus: .leftOpened, withPercent: 1 - percent)
        case .ended:
            if percent >= panGestureSuccessPercent {
                showMainViewController(fromStatus: .leftOpened)
            } else {
                finishShowMenuViewCntrollerAnimating(toSlideMenuStatus: .leftOpened, shouldComplete: true)
            }
        default:
            if percent >= panGestureSuccessPercent {
                showMainViewController(fromStatus: .leftOpened)
            } else {
                finishShowMenuViewCntrollerAnimating(toSlideMenuStatus: .leftOpened, shouldComplete: true)
            }
        }
    }
    
    /**
     Setup close right menu pan gesture
     */
    private func setupCloseRightMenuPanGesture() {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(closeRightMenuPanGestureTriggered(gesture:)))
        self.closeRightMenuPanGestureRecognizer = gesture
        gesture.isEnabled = false
        gesture.delegate = self
        view.addGestureRecognizer(gesture)
    }
    
    func closeRightMenuPanGestureTriggered(gesture: UIPanGestureRecognizer) {
        let percent = fabs(gesture.translation(in: view).x) / view.bounds.size.width
        switch gesture.state {
        case .began:
            break
        case .changed:
            showMenuViewControllerAnimating(toSlideMenuStatus: .rightOpened, withPercent: 1 - percent)
        case .ended:
            if percent >= panGestureSuccessPercent {
                showMainViewController(fromStatus: .rightOpened)
            } else {
                finishShowMenuViewCntrollerAnimating(toSlideMenuStatus: .rightOpened, shouldComplete: true)
            }
        default:
            if percent >= panGestureSuccessPercent {
                showMainViewController(fromStatus: .leftOpened)
            } else {
                finishShowMenuViewCntrollerAnimating(toSlideMenuStatus: .rightOpened, shouldComplete: true)
            }
        }
    }
    
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        switch willTransitionToStatus {
        case .bothClosed:
            return preferredStatusBarStyleForMainMenu
        case .leftOpened:
            return preferredStatusBarStyleForSlideMenu
        case .rightOpened:
            return preferredStatusBarStyleForSlideMenu
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        view.insertSubview(backgroundImageContainerView, at: 0)
        backgroundImageContainerView.addSubview(backgroundImageView)
        view.addSubview(leftMenuContainerView)
        view.addSubview(rightMenuContainerView)
        view.addSubview(mainViewControllerContainerView)

        setupBackgroundImageView()
        
        if let leftVC = leftMenuViewController {
            setup(viewController: leftVC, toContainerView: leftMenuContainerView)
            setupLeftMenuContainerView()
        }
        
        if let rightVC = rightMenuViewController {
            setup(viewController: rightVC, toContainerView: rightMenuContainerView)
            setupRightMenuContainerView()
        }
        
        setup(viewController: mainViewController, toContainerView: mainViewControllerContainerView)
        setupMainViewContainerView()
        view.layoutIfNeeded()
        
        if isLeftScreenEdgePanGestureEnabled && leftMenuViewController != nil {
            setupScreenEdgePanGesture(fromScreenEdge: .left)
            
            setupCloseLeftMenuPanGesture()
        }
        
        if isRightScreenEdgePanGestureEnabled && rightMenuViewController != nil {
            setupScreenEdgePanGesture(fromScreenEdge: .right)
            
            setupCloseRightMenuPanGesture()
        }
        
        disableCloseMenuPanGestureRecognizer()
    }

    override public func didReceiveMemoryWarning() {
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

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil) { (context) in
            self.setupLeftMenuContainerView()
            self.setupRightMenuContainerView()
            self.setupBackgroundImageView()
        }
    }
    /**
     Controls the rotation behaviours.
     When slide menu is shown, rotation will be disabled
     */
    public override var shouldAutorotate: Bool {
        if slideMenuStatus != .bothClosed {
            return false
        } else {
            return true
        }
    }
    /**
     Rotate the image to the given orientation
     
     - parameter image: UIImage
     - parameter toOrientation: The target orientation
     - returns: The rotated image
     */
    private func rotateImage(image: UIImage, toOrientation orientation: UIImageOrientation) -> UIImage {
        return UIImage(cgImage: image.cgImage!, scale: 1, orientation: orientation)
    }
 
}

extension PLParallaxViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let g = gestureRecognizer as? UIPanGestureRecognizer {
            switch slideMenuStatus {
            case .bothClosed:
                return false
            case .leftOpened:
                return g.translation(in: view).x < 0
            case .rightOpened:
                return g.translation(in: view).x > 0
            }
        }
        return false
    }
}

