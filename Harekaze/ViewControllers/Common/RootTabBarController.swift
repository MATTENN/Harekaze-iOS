/**
*
* RootTabBarController.swift
* Harekaze
* Created by Yuki MIZUNO on 2018/01/15.
*
* Copyright (c) 2016-2018, Yuki MIZUNO
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice,
*	this list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice,
*	this list of conditions and the following disclaimer in the documentation
*	 and/or other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors
*	may be used to endorse or promote products derived from this software
*	without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
* ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
* LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
* SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
* INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
* THE POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit
import RealmSwift
import TransitionableTab

class RootTabBarController: UITabBarController {

	// MARK: - Private instance fileds
	private var dataSource: Results<(Download)>!
	private var notificationToken: NotificationToken?
	private var downloadingBadgeValue: Int = 0 {
		didSet {
			if downloadingBadgeValue < 0 {
				downloadingBadgeValue = 0
			}
			if let item = self.tabBar.items?[3] {
				item.badgeValue = downloadingBadgeValue <= 0 ? nil : "\(downloadingBadgeValue)"
			}
		}
	}
	private var currentIndex = 0

	override var selectedIndex: Int {
		didSet {
			self.currentIndex = selectedIndex
		}
	}

	// MARK: - View initialization

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		currentIndex = self.selectedIndex
		self.delegate = self
		if self.childViewControllers.count != 5 {
			return
		}
		if let navigationController = self.childViewControllers[0] as? TransitionableTintColorNavigationController,
			let recordingsViewController = navigationController.topViewController as? RecordingsTableViewController {
			recordingsViewController.refreshDataSource()
		}
		if let navigationController = self.childViewControllers[1] as? TransitionableTintColorNavigationController,
			let timersViewController = navigationController.topViewController as? TimersTableViewController {
			timersViewController.refreshDataSource()
		}
		if let navigationController = self.childViewControllers[2] as? TransitionableTintColorNavigationController,
			let guideViewController = navigationController.topViewController as? GuideViewController {
			guideViewController.refreshDataSource()
		}

		// On-filesystem persistent realm store
		let config = Realm.configuration(class: Download.self)

		// Delete uncompleted download program from realm
		let realm = try! Realm(configuration: config)

		// Load downloaded program list from realm
		dataSource = realm.objects(Download.self)

		// Realm notification
		notificationToken = dataSource.observe(updateNotificationBlock())
	}

	// MARK: - Show program detail method
	func showProgramDetail(program: Program? = nil, recording: Recording? = nil, download: Download? = nil) {
		if self.childViewControllers.count != 5 || (program == nil && recording == nil && download == nil) {
			return
		}
		guard let programDetailViewController = storyboard?.instantiateViewController(withIdentifier: "ProgramDetailTableViewController") as?
			ProgramDetailTableViewController else {
				return
		}
		if let recording = recording {
			self.selectedIndex = 0
			programDetailViewController.program = recording.program
		} else if let download = download {
			self.selectedIndex = 3
			programDetailViewController.program = download.recording?.program
		} else {
			self.selectedIndex = 2
			programDetailViewController.program = program
		}
		guard let navigationController = self.childViewControllers[self.selectedIndex] as? UINavigationController else {
			return
		}
		navigationController.pushViewController(programDetailViewController, animated: true)
	}

	// MARK: - Realm notification

	func updateNotificationBlock<T>() -> ((RealmCollectionChange<T>) -> Void) {
		return { [weak self] (changes: RealmCollectionChange) in
			guard let aSelf = self else {
				return
			}
			switch changes {
			case .initial:
				aSelf.downloadingBadgeValue = 0
			case .update(_, let deletions, let insertions, let modifications):
				let diff = insertions.count - deletions.count
				if diff != 0 {
					aSelf.downloadingBadgeValue += diff
				} else {
					for i in modifications where aSelf.dataSource[i].size != 0 {
						aSelf.downloadingBadgeValue -= 1
					}
				}
			case .error(let error):
				fatalError("\(error)")
			}
		}
	}

	// MARK: - Rotation

	open override var shouldAutorotate: Bool {
		return true
	}

	open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .portrait
	}

	open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		return .portrait
	}
}

// MARK: - TabBarController delegate
extension RootTabBarController: UITabBarControllerDelegate {
	func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
		if currentIndex == selectedIndex {
			if let navigationController = viewController as? TransitionableTintColorNavigationController {
				navigationController.toMainColorNavbar()
			}
		} else {
			if let navigationController = viewControllers?[currentIndex] as? TransitionableTintColorNavigationController {
				if let tableViewController = navigationController.childViewControllers.first as? MasterProgramTableViewController {
					tableViewController.searchController.dismiss(animated: false)
				}
			}
		}
		currentIndex = selectedIndex
	}
}

// MARK: - TransitionableTab delegate
extension RootTabBarController: TransitionableTab {
	func transitionDuration() -> CFTimeInterval {
		return 0.1
	}

	func fromTransitionAnimation(layer: CALayer, direction: Direction) -> CAAnimation {
		return DefineAnimation.move(.from, direction: direction)
	}

	func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
		return animateTransition(tabBarController, shouldSelect: viewController)
	}
}
