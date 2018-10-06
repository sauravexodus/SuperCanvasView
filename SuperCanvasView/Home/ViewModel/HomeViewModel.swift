//
//  HomeViewModel.swift
//  SuperCanvasView
//
//  Created by Krishna C Aluru on 10/6/18.
//  Copyright © 2018 Sourav Chandra. All rights reserved.
//

import Foundation
import RxDataSources
import ReactorKit
import RxSwift

final class HomeViewModel: Reactor {
    enum Action {
        case initialLoad
        case add(ConsultationRow)
        case addTen
        case deleteAll
    }
    
    enum Mutation {
        case appendTenConsultationRows
        case setPages([ConsultationPageSection])
    }
    
    struct State {
        var pages: [ConsultationPageSection] = []
        let pageHeight: Float = 300
    }
    
    let initialState = State()
    
    init() { }
    
    func mutate(action: HomeViewModel.Action) -> Observable<HomeViewModel.Mutation> {
        switch action {
        case .initialLoad: return mutateInitialLoad()
        case let .add(consultationRow): return mutateAppendConsultationRow(consultationRow)
        case .addTen: return .empty()
        case .deleteAll: return mutateInitialLoad()
        }
    }
    
    private func mutateInitialLoad() -> Observable<Mutation> {
        return .just(.setPages([ConsultationPageSection(items: [ConsultationRow(height: currentState.pageHeight, medicalSection: .none)], pageHeight: currentState.pageHeight)]))
    }
    
    private func mutateAppendConsultationRow(_ consultationRow: ConsultationRow) -> Observable<Mutation> {
        let consultationRows = currentState.pages.reduce([], { result, page in return result + page.items.filter { row in row.medicalSection != .none } })
        return .just(.setPages(createPages(for: consultationRows, appending: consultationRow)))
    }
    
    private func createPages(for consultationRows: [ConsultationRow], appending consultationRow: ConsultationRow) -> [ConsultationPageSection] {
        var consultationRows = consultationRows
        let indexToInsert = consultationRows.reduce(consultationRows.count, { result, row in
            guard consultationRow.medicalSection == row.medicalSection else { return result }
            if let index = consultationRows.firstIndex(of: row) { return index + 1 }
            return result
        })
        consultationRows.insert(consultationRow, at: indexToInsert)
        let pages = consultationRows.reduce([], { result, row -> [ConsultationPageSection] in
            var result = result
            guard !result.isEmpty else { return [ConsultationPageSection(items: [row], pageHeight: currentState.pageHeight)] }
            let fullResult = result
            var lastPage = result.removeLast()
            guard lastPage.canInsertRow(with: row.height) else { return fullResult + [ConsultationPageSection(items: [row], pageHeight: currentState.pageHeight)] }
            lastPage.items += [row]
            return result + [lastPage]
        })
        return padPages(pages)
    }
    
    private func padPages(_ pages: [ConsultationPageSection]) -> [ConsultationPageSection] {
        var pagesCopy = pages
        for (index, page) in pages.enumerated() {
            let newItems = page.heightToBePadded != 0 ? [ConsultationRow(height: page.heightToBePadded, medicalSection: .none)] : []
            pagesCopy[index] = ConsultationPageSection(items: page.items + newItems, pageHeight: currentState.pageHeight)
        }
        if let lastPage = pages.last, lastPage.isPageFull {
            pagesCopy.append(ConsultationPageSection(items: [ConsultationRow(height: currentState.pageHeight, medicalSection: .none)], pageHeight: currentState.pageHeight))
        }
        return pagesCopy
    }
    
    func reduce(state: HomeViewModel.State, mutation: HomeViewModel.Mutation) -> HomeViewModel.State {
        var state = state
        switch mutation {
        case .appendTenConsultationRows:
            print("reached here")
        case let .setPages(pages):
            state.pages = pages
        }
        return state
    }
//    private func showPrint() {
//        var images: [UIImage] = []
//        for section in 0...tableView.numberOfSections - 1 {
//            for row in 0...tableView.numberOfRows(inSection: section) - 1 {
//                let indexPath = IndexPath(row: row, section: section)
//                tableView.scrollToRow(at: indexPath, at: .top, animated: false)
//                //                tableView.reloadData()
//                //                tableView.setNeedsLayout()
//                tableView.layoutIfNeeded()
//                let cell = tableView.cellForRow(at: indexPath)
//                cell?.swCapture { image in
//                    guard let `image` = image else { return }
//                    images.append(image)
//                }
//            }
//        }
//        printConsultation(images: images)
//    }
//
//    private func printConsultation(images: [UIImage]) {
//        let pi = UIPrintInfo(dictionary: nil)
//        pi.outputType = .general
//        pi.jobName = "JOB"
//        pi.orientation = .portrait
//        pi.duplex = .longEdge
//        let pic = UIPrintInteractionController.shared
//        pic.printInfo = pi
//        pic.printingItems = images
//        pic.present(animated: true)
//    }
}
