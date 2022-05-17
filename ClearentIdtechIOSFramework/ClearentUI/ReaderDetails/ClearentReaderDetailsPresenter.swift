//
//  ClearentReaderDetailsPresenter.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 17.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//


public protocol ClearentReaderDetailsProtocol {
    var readerInfo: ReaderInfo? { get set }
}

public class ClearentReaderDetailsPresenter: ClearentReaderDetailsProtocol {
    public var readerInfo: ReaderInfo?
    
    public init(readerInfo: ReaderInfo?) {
        self.readerInfo = readerInfo
        ClearentWrapper.shared.searchRecentlyUsedReaders()
    }
}

