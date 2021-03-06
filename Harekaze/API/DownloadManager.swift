/**
*
* DownloadManager.swift
* Harekaze
* Created by Yuki MIZUNO on 2016/08/21.
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
import Alamofire

class DownloadManager: NSObject {
	// MARK: - Shared instance
	static let shared: DownloadManager = DownloadManager()

	// MARK: - Private instance fields
	private var requests: [String: DownloadRequest] = [:]
	private var managers: [String: SessionManager] = [:]
	private var cancelAction: () -> Void = {}

	// MARK: - Initialization
	private override init() {
	}

	// MARK: - Management methods

	func createManager(_ id: String, backgroundCompletionHandler: @escaping () -> Void = {}) -> SessionManager {
		let configuration = URLSessionConfiguration.background(withIdentifier: "org.harekaze.Harekaze.background.\(UUID().uuidString)")
		let manager = SessionManager(configuration: configuration)
		manager.startRequestsImmediately = true
		manager.backgroundCompletionHandler = backgroundCompletionHandler
		self.managers[id] = manager
		return manager
	}

	func addRequest(_ id: String, request: DownloadRequest, cancelAction: @escaping () -> Void) {
		self.requests[id] = request
		self.cancelAction = cancelAction
	}

	func progressRequest(_ id: String) -> Progress? {
		return self.requests[id]?.progress
	}

	func stopRequest(_ id: String) {
		if let request = self.requests[id] {
			request.cancel()
			cancelAction()
			self.requests[id] = nil
		}
	}
}
