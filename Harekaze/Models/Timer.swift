/**
 *
 * Timer.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/08/02.
 * 
 * Copyright (c) 2016-2018, Yuki MIZUNO
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 * 
 * 3. Neither the name of the copyright holder nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
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
import ObjectMapper
import APIKit

class Timer: Program {

	// MARK: - Shared dataSource
	static var timers: Results<(Timer)>! = {
		let predicate = NSPredicate(format: "startTime > %@", Date() as CVarArg)
		let realm = try! Realm()
		return realm.objects(Timer.self).filter(predicate).sorted(byKeyPath: "startTime", ascending: true)
	}()

	// MARK: - Managed instance fileds
	@objc dynamic var conflict: Bool = false
	@objc dynamic var manual: Bool = false
	@objc dynamic var skip: Bool = false

	// MARK: - Class initialization
	required convenience init?(map: Map) {
		self.init()
		mapping(map: map)
	}

	convenience init(with value: Program) {
		self.init()
		id = value.id
		title = value.title
		fullTitle = value.fullTitle
		subTitle = value.subTitle
		detail = value.detail
		attributes = value.attributes
		genre = value.genre
		channel = value.channel
		episode = value.episode
		startTime = value.startTime
		endTime = value.endTime
		duration = value.duration
		conflict = false
		manual = false
		skip = false
	}

	// MARK: - JSON value mapping
	override func mapping(map: Map) {
		super.mapping(map: map)
		conflict <- map["isConflict"]
		manual <- map["isManualReserved"]
		skip <- map["isSkip"]
	}

	// MARK: - Static method

	static func refreshTimers(onSuccess: (() -> Void)?, onFailure: ((SessionTaskError) -> Void)?) {
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		let start = CFAbsoluteTimeGetCurrent()
		let request = ChinachuAPI.TimerRequest()
		Session.send(request) { result in
			switch result {
			case .success(let data):
				// Store timer list to realm
				DispatchQueue.global().async {
					let realm = try! Realm()
					try! realm.write {
						realm.add(data, update: true)
						let objectsToDelete = realm.objects(Timer.self).filter { data.index(of: $0) == nil }
						realm.delete(objectsToDelete)
					}
					let end = CFAbsoluteTimeGetCurrent()
					let wait = max(0.0, 3.0 - (end - start))
					DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
						onSuccess?()
						UIApplication.shared.isNetworkActivityIndicatorVisible = false
					}
				}
			case .failure(let error):
				onFailure?(error)
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
			}
		}
	}
}
