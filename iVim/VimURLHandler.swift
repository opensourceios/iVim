//
//  VimURLHandler.swift
//  iVim
//
//  Created by Terry on 9/21/17.
//  Copyright © 2017 Boogaloo. All rights reserved.
//

import Foundation

enum VimURLType {
    case scheme
    case font
    case text
    
    init?(url: URL) {
        if URLSchemeWorker.isValid(url) {
            self = .scheme
        } else if url.isSupportedFont {
            self = .font
        } else {
            self = .text
        }
    }
}

private enum URLMode {
    case local
    case copy
    case open
    
    init?(url: URL) {
        if url.isDecendentOf(URL.inboxDirectory) {
            self = .copy
        } else if url.isDecendentOf(URL.documentsDirectory) {
            self = .local
        } else {
            self = .open
        }
    }
}

extension URL {
    func isDecendentOf(_ url: URL?) -> Bool {
        guard let u = url else { return false }
        let path = self.resolvingSymlinksInPath().path
        
        return path.hasPrefix(u.resolvingSymlinksInPath().path)
    }
}

struct VimURLHandler {
    let url: URL
    let type: VimURLType
}

extension VimURLHandler {
    init?(url: URL?) {
        guard let u = url, let t = VimURLType(url: u) else { return nil }
        self.init(url: u, type: t)
    }
    
    func open() -> Bool {
        switch self.type {
        case .scheme: return URLSchemeWorker(url: self.url)!.run()
        case .font: return self.importFont()
        case .text: return self.importText()
        }
    }
    
    private func importFont() -> Bool {
        guard let mode = URLMode(url: self.url) else { return false }
        let isMoving: Bool
        let removeOrigin: Bool
        switch mode {
        case .local, .open:
            isMoving = false
            removeOrigin = false
        case .copy:
            isMoving = true
            removeOrigin = true
        }
        
        return gFM.importFont(from: self.url, isMoving: isMoving, removeOriginIfFailed: removeOrigin)
    }
    
    private func importText() -> Bool {
        guard let mode = URLMode(url: self.url) else { return false }
        switch mode {
        case .local: gOpenFile(at: self.url)
        case .copy:
            guard let path = FileManager.default.safeMovingItem(
                from: self.url,
                into: URL.documentsDirectory) else { return false }
            gOpenFile(at: path)
        case .open:
            gPIM.addPickInfo(for: self.url, task: {
                gOpenFile(at: $0)
            })
        }
        
        return true
    }
}