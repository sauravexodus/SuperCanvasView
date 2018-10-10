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
    typealias IndexPathWithScrollPosition = (indexPath: IndexPath, scrollPosition: UITableViewScrollPosition)

    enum Action {
        case initialLoad
        case select(MedicalSection)
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

// MARK: Mutations

extension HomeViewModel {
    private func mutateInitialLoad() -> Observable<Mutation> {
        return .just(.setPages([ConsultationPageSection(items: [ConsultationRow(height: currentState.pageHeight, lines: [], medicalTerm: Symptom(name: nil), needsHeader: true)], pageHeight: currentState.pageHeight)]))
    }
    
    private func mutateSelectMedicalSection(_ medicalSection: MedicalSection) -> Observable<Mutation> {
        
        let currentSectionItems = currentState.pages.enumerated()
            .reduce([], { result, page in
                return result + page.element.items.enumerated().map { offset, item in
                    return (sectionIndex: page.offset, itemIndex: offset, item: item)
                }
            })
            .filter {
                sectionIndex, itemIndex, item in item.medicalTerm.sectionOfSelf == medicalSection
            }

        guard let firstRow = currentSectionItems.first else { return .empty() }
        guard let lastRow = currentSectionItems.last else { return .empty() }
        var mutations: [Observable<Mutation>] = []
        
        if (lastRow.item.isPadder && lastRow.item.height < 50) || !lastRow.item.isPadder {
            var medicalTerm = lastRow.item.medicalTerm
            medicalTerm.name = nil
            mutations.append(mutateAppendConsultationRow(ConsultationRow(height: 50, lines: [], medicalTerm: medicalTerm)))
        } else {
            let consultationRows = currentState.pages.reduce([], { result, page in return result + page.items.filter { row in !row.isPadder } })
            let pages = createPages(for: consultationRows, appending: nil)

            mutations.append(.just(.setPages(pages)))
        }
        
        let indexPath = IndexPathWithScrollPosition(
            indexPath: IndexPath(row: firstRow.itemIndex, section: firstRow.sectionIndex),
            scrollPosition: .top
        )
        
        mutations.append(.just(.setFocusedIndexPath(indexPath)))
        return Observable.concat(mutations)
    }
    
    private func mutateAppendConsultationRow(_ consultationRow: ConsultationRow) -> Observable<Mutation> {
        
        let consultationRows = currentState.pages.reduce([], { result, page in return result + page.items.filter { row in !row.isPadder } })
        let pages = createPages(for: consultationRows, appending: consultationRow)
        
        let indexPath = pages.enumerated()
            .reduce([], { result, page in
                return result + page.element.items.enumerated().map { offset, item in
                    return (sectionIndex: page.offset, itemIndex: offset, item: item)
                }
            })
            .first { sectionIndex, itemIndex, item in
                item == consultationRow
            }
            .map { sectionIndex, itemIndex, item in
                IndexPathWithScrollPosition(indexPath: IndexPath(row: itemIndex, section: sectionIndex), scrollPosition: .none)
            }
        
        guard let foundPath = indexPath else { return .empty() }
        
        return .concat(.just(.setPages(pages)), .just(.setFocusedIndexPath(foundPath)))
    }
}

// MARK: Helpers

extension HomeViewModel {
    private func createPages(for consultationRows: [ConsultationRow], appending consultationRow: ConsultationRow?) -> [ConsultationPageSection] {
        var consultationRows = consultationRows
        var consultationRow = consultationRow
        // set needs header if it is the first item of it's kind
        let needsHeader = !consultationRows.contains { row in row.medicalTerm.sectionOfSelf == consultationRow?.medicalTerm.sectionOfSelf }
        consultationRow?.needsHeader = needsHeader
        // find index to insert the new row in
        let indexToInsert = consultationRows.reduce(consultationRows.count, { result, row in
            guard let `consultationRow` = consultationRow, consultationRow.medicalTerm.sectionOfSelf == row.medicalTerm.sectionOfSelf else {
                return result
            }
            if let index = consultationRows.index(of: row) { return index + 1 }
            return result
        })
        if let `consultationRow` = consultationRow {
            consultationRows.insert(consultationRow, at: indexToInsert)
        }
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
}
