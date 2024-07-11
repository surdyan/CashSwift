//
//  MainTabViewController.swift
//  cashdine1
//
//  Created by Vasyl Maryna on 28.04.2024.
//

import SwiftUI
import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad () {
        super.viewDidLoad ()
        generateTabBar ()
    }
    
    private func generateTabBar () {
        viewControllers = [
            generateVC (viewController: CameraViewController(), title: "Home", image: UIImage(systemName: "house.fill")),
            generateVC (viewController: ProfileView(), title: "Personal Info", image: UIImage (systemName: "person.fill")),
            generateVC (viewController: RestaurantView(), title: "Settings", image: UIImage (systemName: "slider.horizontal.3"))
        ]
    }
    
    private func generateVC (viewController: UIViewController, title: String, image: UIImage?) ->
    UIViewController {
        viewController.tabBarItem.title = title
        viewController.tabBarItem.image = image
        return viewController
    }
}



#Preview {
    MainTabBarController()
}
