//  Created by iWw on 2021/7/26.
//

import UIKit

open class InsetLayout: UICollectionViewFlowLayout {
    
    /// Required
    public private(set) weak var insetLayoutDelegate: InsetLayoutDelegate!
    /// Section decoration, optional
    public private(set) weak var sectionDecorationDelegate: SectionDecorationDelegate?
    
    private var itemAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    
    public required init(insetLayoutDelegate: InsetLayoutDelegate, sectionDecorationDelegate: SectionDecorationDelegate? = nil) {
        self.insetLayoutDelegate = insetLayoutDelegate
        self.sectionDecorationDelegate = sectionDecorationDelegate
        super.init()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func reset() {
        itemAttributes.removeAll()
        insetMap.removeAll()
        lineSpacingMap.removeAll()
        interitemSpacingMap.removeAll()
        sizeMap.removeAll()
        indexPaths.removeAll()
        
        headerSizeMap.removeAll()
        headerArributes.removeAll()
        
        footerSizeMap.removeAll()
        footerAttributes.removeAll()
        
        sectionLastIndex.removeAll()
        decorationTypeMap.removeAll()
        decorationAttributesMap.removeAll()
    }
    
    // MARK: - overrides
    open override func prepare() {
        super.prepare()
        
        reset()
        layout()
    }
    
    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        itemAttributes[indexPath]
    }
    
    open override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == UICollectionView.elementKindSectionHeader {
            return headerArributes[indexPath.section]
        } else if elementKind == UICollectionView.elementKindSectionFooter {
            return footerAttributes[indexPath.section]
        }
        return nil
    }
    
    open override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        decorationAttributesMap[indexPath.section]
    }
    
    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let ia = itemAttributes.filter { element -> Bool in
            rect.intersects(element.value.frame)
        }
        var attributes = ia.map { $0.value }
        
        // append header
        for attr in attributes {
            guard let headerAttr = layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: attr.indexPath) else {
                continue
            }
            attributes.append(headerAttr)
        }
        
        // append footer
        for attr in attributes {
            guard let footerAttr = layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, at: attr.indexPath) else {
                continue
            }
            attributes.append(footerAttr)
        }
        
        // append decoration
        let sections = attributes.map({ $0.indexPath.section }) // find all `section` in rect and append decoration attributes of `section`
        for section in sections {
            guard let decorationAttribute = decorationAttributesMap[section] else {
                continue
            }
            attributes.append(decorationAttribute)
        }
        return attributes
    }
    
    open override var collectionViewContentSize: CGSize {
        contentSize
    }
    
    private var contentSize: CGSize = .zero
    private var insetMap: [Int: UIEdgeInsets] = [:]
    private var lineSpacingMap: [Int: CGFloat] = [:]
    private var interitemSpacingMap: [Int: CGFloat] = [:]
    private var sizeMap: [IndexPath: CGSize] = [:]
    private var indexPaths: [IndexPath] = []
    
    // header
    private var headerSizeMap: [Int: CGSize] = [:]
    private var headerArributes: [Int: UICollectionViewLayoutAttributes] = [:]
    // footer
    private var footerSizeMap: [Int: CGSize] = [:]
    private var footerAttributes: [Int: UICollectionViewLayoutAttributes] = [:]
    
    // section: item
    private var sectionLastIndex: [Int: Int] = [:]
    private var decorationTypeMap: [Int: UICollectionReusableView.Type] = [:]
    private var decorationAttributesMap: [Int: UICollectionViewLayoutAttributes] = [:]
    
    private var contentWidth: CGFloat = 0
}

private extension InsetLayout {
    func registerDecoration() {
        
        guard let delegate = sectionDecorationDelegate, let collectionView = collectionView else { return }
        
        for section in 0 ..< collectionView.numberOfSections {
            guard let type = delegate.decorationType(at: section) else {
                continue
            }
            decorationTypeMap[section] = type
            register(type, forDecorationViewOfKind: "\(String(reflecting: type.self))")
        }
        
        // cache decoration attributes
        for (_, attr) in itemAttributes {
            guard let decorationDelegate = sectionDecorationDelegate else { continue }
            
            guard let type = decorationTypeMap[attr.indexPath.section] else {
                continue
            }
            guard decorationAttributesMap[attr.indexPath.section] == nil else {
                continue
            }
            // start item
            guard let startAttributes = layoutAttributesForItem(at: .init(item: 0, section: attr.indexPath.section)),
                  // end item
                  let lastAttributes = layoutAttributesForItem(at: .init(item: sectionLastIndex[attr.indexPath.section] ?? 0, section: attr.indexPath.section))
            else {
                continue
            }
            
            let shouldContainsInset = decorationDelegate.decorationBoundsContainsInset(at: attr.indexPath.section)
            let shouldContainsContentInset = decorationDelegate.decorationBoundsContainsContentInset(at: attr.indexPath.section)
            let shouldContainsHeader = decorationDelegate.decorationBoundsContainsHeader(at: attr.indexPath.section)
            let shouldContainsFooter = decorationDelegate.decorationBoundsContainsFooter(at: attr.indexPath.section)
            
            let spacingHeader = insetLayoutDelegate.spacingBetweenFirstItemAndHeader(at: attr.indexPath.section)
            let spacingFooter = insetLayoutDelegate.spacingBetweenLastItemAndFooter(at: attr.indexPath.section)
            
            let decorationAttributes = UICollectionViewLayoutAttributes(forDecorationViewOfKind: "\(String(reflecting: type.self))", with: startAttributes.indexPath)
            decorationAttributes.zIndex = startAttributes.zIndex - 1
            
            // 计算 frame，这里初始化的 frame 默认没有忽略 inset 和 contentInset
            // calculate frame, initialized frame not ignore inset and contentInset
            var frame = startAttributes.frame.union(lastAttributes.frame)
            
            let inset = insetMap[attr.indexPath.section] ?? .zero
            var contentWidth = collectionView.frame.width - collectionView.contentInset.left - collectionView.contentInset.right - inset.left - inset.right
            var contentHeight = frame.height
            
            contentHeight += (spacingHeader + spacingFooter)
            frame.origin.y -= spacingHeader
            
            if shouldContainsContentInset { // contains contentInset
                contentWidth += (collectionView.contentInset.left + collectionView.contentInset.right)
                frame.origin.x -= collectionView.contentInset.left
            }
            
            if shouldContainsInset { // contains inset
                contentWidth += (inset.left + inset.right)
                
                frame.origin.x -= inset.left
                frame.origin.y -= inset.top
                contentHeight += (inset.top + inset.bottom)
            }
            
            if shouldContainsHeader { // contains header
                let headerSize = headerSize(for: attr.indexPath.section)
                frame.origin.y -= headerSize.height
                contentHeight += headerSize.height
            }
            
            if shouldContainsFooter { // contains footer
                let footerSize = footerSize(for: attr.indexPath.section)
                contentHeight += footerSize.height
            }
            
            frame.size.width = contentWidth
            frame.size.height = contentHeight
            decorationAttributes.frame = frame
            decorationAttributesMap[attr.indexPath.section] = decorationAttributes
        }
    }
    
    func layout() {
        guard let collectionView = collectionView else { return }
        defer {
            registerDecoration()
        }
        
        // 获取所有 indexPath
        for section in 0 ..< collectionView.numberOfSections {
            insetMap[section] = insetLayoutDelegate.inset(at: section)
            lineSpacingMap[section] = insetLayoutDelegate.lineSpacing(at: section)
            interitemSpacingMap[section] = insetLayoutDelegate.interitemSpacing(at: section)
            
            // get header size
            if let headerSize = (collectionView.delegate as? UICollectionViewDelegateFlowLayout)?.collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: section), headerSize != .zero {
                headerSizeMap[section] = headerSize
            }
            // get footer size
            if let footerSize = (collectionView.delegate as? UICollectionViewDelegateFlowLayout)?.collectionView?(collectionView, layout: self, referenceSizeForFooterInSection: section), footerSize != .zero {
                footerSizeMap[section] = footerSize
            }
            
            for item in 0 ..< collectionView.numberOfItems(inSection: section) {
                indexPaths.append(.init(item: item, section: section))
                sectionLastIndex[section] = item
            }
        }
        
        // 获取所有 indexPath 对应的 size
        for indexPath in indexPaths {
            guard let flowLayout = collectionView.delegate as? UICollectionViewDelegateFlowLayout else {
                fatalError("collectionView.delgate 必须遵循 `UICollectionViewDelegateFlowLayout`")
            }
            guard let size = flowLayout.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) else {
                sizeMap[indexPath] = .zero
                continue
            }
            sizeMap[indexPath] = size
        }
        
        // 内容宽度
        self.contentWidth = collectionView.frame.width - collectionView.contentInset.left - collectionView.contentInset.right
        
        var previousFrame: CGRect = .zero
        
        // 计算位置
        for indexPath in indexPaths {
            
            // build header
            var frame = buildHeaderAttributes(with: indexPath, previousFrame: previousFrame)
            frame = buildItemAttributes(with: indexPath, previousFrame: frame)
            frame = buildFooterAttributes(with: indexPath, previousFrame: frame)
            
            previousFrame = frame
            
            contentSize = .init(width: contentWidth, height: frame.maxY)
        }
    }
}

// MARK: Calculator
private extension InsetLayout {
    
    func buildHeaderAttributes(with indexPath: IndexPath, previousFrame: CGRect) -> CGRect {
        guard indexPath.item == 0, headerSize(for: indexPath.section) != .zero else {
            // 不存在，embed inset top
            if indexPath.item == 0, indexPath.section != 0 { // is first item, and is not first section
                var newFrame = previousFrame
                newFrame.origin.y += (insetMap[indexPath.section] ?? .zero).top
                return newFrame
            }
            return previousFrame
        }
        
        // 一个新的头部
        // x 从 初始位置开始, y 为 maxY
        var frame = CGRect(origin: .zero, size: headerSize(for: indexPath.section))
        frame.origin.y += previousFrame.maxY
        
        // embed inset
        if indexPath.section != 0 {
            let inset = insetMap[indexPath.section] ?? .zero
            frame.origin.x = inset.left
            if indexPath.section != 0 {
                frame.origin.y += inset.top
            }
        }
        
        // 警告提示
        if frame.width > contentWidth {
            print("⚠️ [InsetLayout]: Header for indexPath: \(indexPath)'s width: \(frame.width) is great than contentWidth: \(contentWidth)")
        }
        
        let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: indexPath)
        attributes.frame = frame
        headerArributes[indexPath.section] = attributes
        return frame
    }
    
    func buildFooterAttributes(with indexPath: IndexPath, previousFrame: CGRect) -> CGRect {
        guard indexPath.item == sectionLastIndex[indexPath.section], footerSize(for: indexPath.section) != .zero else {
            // 不存在, embed inset.bottom
            if indexPath.item == sectionLastIndex[indexPath.section] { // is last item
                var newFrame = previousFrame
                // insert inset.bottom
                newFrame.origin.y += (insetMap[indexPath.section] ?? .zero).bottom
                // insert spacing last and footer
                newFrame.origin.y += insetLayoutDelegate.spacingBetweenLastItemAndFooter(at: indexPath.section)
                return newFrame
            }
            return previousFrame
        }
        
        // 一个新的尾部
        // x 从 初始位置开始, y 为 maxY
        var frame = CGRect(origin: .zero, size: footerSize(for: indexPath.section))
        frame.origin.x = 0
        frame.origin.y += previousFrame.maxY
        
        // embed spacing between last item and footer
        frame.origin.y += insetLayoutDelegate.spacingBetweenLastItemAndFooter(at: indexPath.section)
        
        let footerAttr = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, with: indexPath)
        footerAttr.frame = frame
        footerAttributes[indexPath.section] = footerAttr
        return frame
    }
    
    func buildItemAttributes(with indexPath: IndexPath, previousFrame: CGRect) -> CGRect {
        var frame = frame(for: indexPath)
        // 初始位置
        frame.origin.x += previousFrame.maxX
        frame.origin.y += previousFrame.maxY
        
        let sectionContentWidth = contentWidth // - sectionHorizontalPadding(for: indexPath)
        
        // 是否需要换到下一行
        let shouldNewLine = frame.maxX > sectionContentWidth || (indexPath.item == 0 && indexPath.section != 0 && (insetMap[indexPath.section] ?? .zero) != .zero)
        if shouldNewLine { // 换行
            frame.origin.x = newLineX(at: indexPath)
            frame.origin.y = newLineY(at: indexPath) + previousFrame.maxY
            
            if indexPath.item == 0 { // embed spacing between first and header
                frame.origin.y += insetLayoutDelegate.spacingBetweenFirstItemAndHeader(at: indexPath.section)
            }
        } else {
            // 同一行
            frame.origin.y = previousFrame.minY
        }
        
        #if DEBUG
        if frame.width > contentWidth {
            print("⚠️ [InsetLayout]: Cell for indexPath: \(indexPath)'s width: \(frame.width) is great than contentWidth: \(contentWidth), diff value: \(frame.width - contentWidth)")
        }
        
        let diffValue = (frame.maxX - sectionHorizontal(for: indexPath).right) - (contentWidth - sectionHorizontalPadding(for: indexPath))
        if diffValue >= 0.01 {
            print("⚠️ [InsetLayout]: Cell for indexPath: \(indexPath)'s maxX: \(frame.maxX - sectionHorizontal(for: indexPath).right) is great than safeAreaWidth: \(contentWidth - sectionHorizontalPadding(for: indexPath)), diff value: \(diffValue)")
        }
        #endif
        
        // 构建布局信息
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attributes.frame = frame
        itemAttributes[indexPath] = attributes
        return frame
    }
}

// MARK: Item
private extension InsetLayout {
    
    func size(for indexPath: IndexPath) -> CGSize {
        sizeMap[indexPath] ?? .zero
    }
    
    func sectionHorizontal(for indexPath: IndexPath) -> (left: CGFloat, right: CGFloat) {
        let inset = insetMap[indexPath.section] ?? .zero
        return (left: inset.left, right: inset.right)
    }
    
    func sectionHorizontalPadding(for indexPath: IndexPath) -> CGFloat {
        let inset = sectionHorizontal(for: indexPath)
        return inset.left + inset.right
    }
    
    // 起始位置
    /// start x of new line
    func newLineX(at indexPath: IndexPath) -> CGFloat {
        let inset = insetMap[indexPath.section] ?? .zero
        return inset.left
    }
    /// start y of new line
    func newLineY(at indexPath: IndexPath) -> CGFloat {
        if indexPath.item == 0 {
            return 0
        }
        return lineSpacingMap[indexPath.section] ?? 0
    }
    
    func frame(for indexPath: IndexPath) -> CGRect {
        var frame = CGRect(origin: .zero, size: size(for: indexPath))
        
        if indexPath.item == 0 { // 第 0 个，加上 paddingInset 和 header.height
            let inset = insetMap[indexPath.section] ?? .zero
            frame.origin.x += inset.left
        } else {
            // 非 0 个, 加上指定该 section 指定的 item spacing
            frame.origin.x += interitemSpacingMap[indexPath.section] ?? 0
        }
        
        return frame
    }
}

// MARK: Header
private extension InsetLayout {
    
    func headerFrame(for section: Int) -> CGRect {
        var frame = CGRect(origin: .zero, size: headerSize(for: section))
        frame.origin.y = (insetMap[section] ?? .zero).top
        return frame
    }
    
    func headerSize(for section: Int) -> CGSize {
        headerSizeMap[section] ?? .zero
    }
    
}

// MARK: Footer
private extension InsetLayout {
    
    func footerFrame(for section: Int) -> CGRect {
        .init(origin: .zero, size: footerSize(for: section))
    }
    func footerSize(for section: Int) -> CGSize {
        footerSizeMap[section] ?? .zero
    }
}
