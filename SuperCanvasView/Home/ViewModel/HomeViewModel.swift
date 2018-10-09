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
        case select(MedicalTerm.MedicalSection)
        case add(ConsultationRow)
        case deleteAll
    }
    
    enum Mutation {
        case setPages([ConsultationPageSection])
        case setFocusedIndexPath(IndexPathWithScrollPosition)
    }
    
    struct State {
        var pages: [ConsultationPageSection] = []
        let pageHeight: Float = 300
        var focusedIndexPath: IndexPathWithScrollPosition?
    }
    
    typealias IndexPathWithScrollPosition = (indexPath: IndexPath, scrollPosition: UITableViewScrollPosition)
    
    let initialState = State()
    
    init() { }
    
    func mutate(action: HomeViewModel.Action) -> Observable<HomeViewModel.Mutation> {
        switch action {
        case .initialLoad: return mutateInitialLoad()
        case let .select(medicalSection): return mutateSelectMedicalSection(medicalSection)
        case let .add(consultationRow): return mutateAppendConsultationRow(consultationRow)
        case .deleteAll: return mutateInitialLoad()
        }
    }
    
    private func mutateInitialLoad() -> Observable<Mutation> {
        return .just(.setPages([ConsultationPageSection(items: [ConsultationRow(height: currentState.pageHeight, medicalTerm: MedicalTerm(name: nil, lines: [], medicalSection: .symptoms), needsHeader: true)], pageHeight: currentState.pageHeight)]))
    }
    
    private func mutateSelectMedicalSection(_ medicalSection: MedicalTerm.MedicalSection) -> Observable<Mutation> {
        let indexPath = currentState.pages.enumerated()
            .reduce([], { result, page in
                return result + page.element.items.enumerated().map { offset, item in return (sectionIndex: page.offset, itemIndex: offset, item: item) }
            })
            .first { sectionIndex, itemIndex, item in item.medicalTerm.medicalSection == medicalSection }
            .map { sectionIndex, itemIndex, _ in IndexPathWithScrollPosition(indexPath: IndexPath(row: itemIndex, section: sectionIndex), scrollPosition: .top) }
        guard let foundPath = indexPath else { return .empty() }
        return .just(.setFocusedIndexPath(foundPath))
    }
    
    private func mutateAppendConsultationRow(_ consultationRow: ConsultationRow) -> Observable<Mutation> {
        let consultationRows = currentState.pages.reduce([], { result, page in return result + page.items.filter { row in !row.medicalTerm.isPadder } })
        let pages = createPages(for: consultationRows, appending: consultationRow)
        let indexPath = pages.enumerated()
            .reduce([], { result, page in
                return result + page.element.items.enumerated().map { offset, item in return (sectionIndex: page.offset, itemIndex: offset, item: item) }
            })
            .first { sectionIndex, itemIndex, item in item == consultationRow }
            .map { sectionIndex, itemIndex, item in
                IndexPathWithScrollPosition(indexPath: IndexPath(row: itemIndex, section: sectionIndex), scrollPosition: .none)
        }
        guard let foundPath = indexPath else { return .empty() }
        return .concat(.just(.setPages(pages)), .just(.setFocusedIndexPath(foundPath)))
    }
    
    private func createPages(for consultationRows: [ConsultationRow], appending consultationRow: ConsultationRow) -> [ConsultationPageSection] {
        var consultationRows = consultationRows
        var consultationRow = consultationRow
        // set needs header if it is the first item of it's kind
        consultationRow.needsHeader = !consultationRows.contains(where: { row in row.medicalTerm.medicalSection == consultationRow.medicalTerm.medicalSection })
        // find index to insert the new row in
        let indexToInsert = consultationRows.reduce(consultationRows.count, { result, row in
            guard consultationRow.medicalTerm.medicalSection == row.medicalTerm.medicalSection else { return result }
            if let index = consultationRows.index(of: row) { return index + 1 }
            return result
        })
        consultationRows.insert(consultationRow, at: indexToInsert)
        // create pages after inserting row
        let pages = consultationRows.reduce([], { result, row -> [ConsultationPageSection] in
            var result = result
            guard !result.isEmpty else { return [ConsultationPageSection(items: [row], pageHeight: currentState.pageHeight)] }
            let fullResult = result
            var lastPage = result.removeLast()
            guard lastPage.canInsertRow(with: row.height) else { return fullResult + [ConsultationPageSection(items: [row], pageHeight: currentState.pageHeight)] }
            lastPage.items += [row]
            return result + [lastPage]
        })
        // pad the pages and return them
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
        case let .setFocusedIndexPath(indexPath):
            state.focusedIndexPath = indexPath
        }
        return state
    }
}
