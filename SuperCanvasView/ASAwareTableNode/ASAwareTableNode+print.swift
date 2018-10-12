//
//  ASAwareTableNode+print.swift
//  SuperCanvasView
//
//  Created by Sourav Chandra on 12/10/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import RxSwift

// MARK: Printing

extension ASAwareTableNode {
    func generatePages() -> Observable<[UIImage]> {
        return Observable<Int>.interval(0.2, scheduler: MainScheduler.instance)
            .take(numberOfSections)
            .concatMap { [weak self] section -> Observable<UIImage?> in
                guard let strongSelf = self else { return .just(nil) }
                return strongSelf.captureSinglePage(section)
            }
            .unwrap()
            .reduce([], accumulator: { images, page in
                var `images` = images
                images.append(page)
                return images
            })
            .do(onDispose: { [weak self] in
                self?.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            })
    }
    
    private func captureSinglePage(_ section: Int) -> Observable<UIImage?> {
        return Observable.from(Array(0...numberOfRows(inSection: section) - 1))
            .concatMap { [weak self] row -> Observable<UIImage?> in
                guard let strongSelf = self else { return .just(nil) }
                let indexPath = IndexPath(row: row, section: section)
                strongSelf.scrollToRow(at: indexPath, at: .top, animated: true)
                let cell = strongSelf.cellForRow(at: indexPath)
                return cell?.contentView.rx.swCapture() ?? .just(nil)
            }
            .unwrap()
            .reduce([], accumulator: { images, image in
                var `images` = images
                images.append(image)
                return images
            })
            .map { $0.mergeToSingleImage() }
    }
}
