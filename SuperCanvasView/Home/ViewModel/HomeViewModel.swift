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
        case select(MedicalSection)
        case add(ConsultationRow)
        case deleteAll
    }
    
    enum Mutation {
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
        case let .select(medicalSection): return .empty()
        case let .add(consultationRow): return mutateAppendConsultationRow(consultationRow)
        case .deleteAll: return mutateInitialLoad()
        }
    }
    
    private func mutateInitialLoad() -> Observable<Mutation> {
        return .just(.setPages([ConsultationPageSection(items: [ConsultationRow(height: currentState.pageHeight, medicalSection: .symptoms(name: nil, lines: []))], pageHeight: currentState.pageHeight)]))
    }
    
    private func mutateAppendConsultationRow(_ consultationRow: ConsultationRow) -> Observable<Mutation> {
        let consultationRows = currentState.pages.reduce([], { result, page in return result + page.items.filter { row in !row.medicalSection.isPadder } })
        return .just(.setPages(createPages(for: consultationRows, appending: consultationRow)))
    }
    
    private func createPages(for consultationRows: [ConsultationRow], appending consultationRow: ConsultationRow) -> [ConsultationPageSection] {
        var consultationRows = consultationRows
        let indexToInsert = consultationRows.reduce(consultationRows.count, { result, row in
            guard consultationRow.medicalSection == row.medicalSection else { return result }
            if let index = consultationRows.index(of: row) {
                return index + 1
            }
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
            var newItems: [ConsultationRow] = []
            if let paddingRow = page.paddingRow { newItems = [paddingRow] }
            pagesCopy[index] = ConsultationPageSection(items: page.items + newItems, pageHeight: currentState.pageHeight)
        }
        if let lastPage = pages.last, let nextPage = lastPage.nextPage {
            pagesCopy.append(nextPage)
        }
        return pagesCopy
    }
    
    func reduce(state: HomeViewModel.State, mutation: HomeViewModel.Mutation) -> HomeViewModel.State {
        var state = state
        switch mutation {
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
