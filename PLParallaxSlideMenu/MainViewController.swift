//
//  MainViewController.swift
//  PLParallaxSlideMenu
//
//  Created by Paul Zhang on 27/12/2016.
//  Copyright © 2016 Paul Zhang. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    @IBAction func showLeftMenuButtonTapped(_ sender: UIButton) {
        showLeftMenu()
    }
    
    @IBAction func showRightMenuButtonTapped(_ sender: UIButton) {
        showRightMenu()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
