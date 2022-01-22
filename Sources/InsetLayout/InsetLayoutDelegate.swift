//
//  InsetLayoutDelegate.swift
//  InsetLayout
//
//  Created by iWw on 2022/1/22.
//

import UIKit

public protocol InsetLayoutDelegate: AnyObject {
    
    /// Inset only for the specified section, default is .zero
    func inset(at section: Int) -> UIEdgeInsets
    
    /// Line spacing for the specified section, default is 0
    func lineSpacing(at section: Int) -> CGFloat
    
    /// Interitem spacing for the specified section, default is 0
    func interitemSpacing(at section: Int) -> CGFloat
    
    /// The spacing between the first item and the title, default is 0
    func spacingBetweenFirstItemAndHeader(at secton: Int) -> CGFloat
    func spacingBetweenLastItemAndFooter(at section: Int) -> CGFloat
}

// MARK: Default implemention
public extension InsetLayoutDelegate {
    
    func inset(at section: Int) -> UIEdgeInsets { .zero }
    func lineSpacing(at section: Int) -> CGFloat { 0 }
    func interitemSpacing(at section: Int) -> CGFloat { 0 }
    func spacingBetweenFirstItemAndHeader(at secton: Int) -> CGFloat { 0 }
    func spacingBetweenLastItemAndFooter(at section: Int) -> CGFloat { 0 }
}
