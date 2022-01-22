//
//  SectionDecorationDelegate.swift
//  InsetLayout
//
//  Created by iWw on 2022/1/22.
//

import UIKit

public protocol SectionDecorationDelegate: AnyObject {
    
    /// decoration at section, default is nil
    func decorationType(at section: Int) -> UICollectionReusableView.Type?
    
    /// defulat is false
    func decorationBoundsContainsInset(at section: Int) -> Bool
    /// default is false
    func decorationBoundsContainsContentInset(at section: Int) -> Bool
    
    /// should decoration bounds contains header, default is true
    func decorationBoundsContainsHeader(at section: Int) -> Bool
    
    /// should decoration bounds contains footer, default is true
    func decorationBoundsContainsFooter(at section: Int) -> Bool
}


// MARK: Default implemention
public extension SectionDecorationDelegate {
    
    func decorationType(at section: Int) -> UICollectionReusableView.Type? { nil }
    
    func decorationBoundsContainsInset(at section: Int) -> Bool { false }
    func decorationBoundsContainsContentInset(at section: Int) -> Bool { false }
    
    func decorationBoundsContainsHeader(at section: Int) -> Bool { true }
    func decorationBoundsContainsFooter(at section: Int) -> Bool { true }
}
