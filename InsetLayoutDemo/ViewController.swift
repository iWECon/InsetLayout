//
//  ViewController.swift
//  InsetLayoutDemo
//
//  Created by iWw on 2021/8/18.
//

import UIKit
import InsetLayout
import PinLayout

class ViewController: UIViewController {
    
    class ControlBar: UIView {
        
        class Bar: UIView {
            let nameLabel = UILabel()
            let valueLabel = UILabel()
            let slider = UISlider()
            
            required init(title: String, min: Float, max: Float) {
                super.init(frame: .zero)
                slider.minimumValue = min
                slider.maximumValue = max
                nameLabel.text = title
                
                nameLabel.font = .systemFont(ofSize: 12)
                valueLabel.font = .systemFont(ofSize: 12, weight: .medium)
                
                valueLabel.text = "\(min)"
                
                addSubview(nameLabel)
                addSubview(valueLabel)
                addSubview(slider)
                
                slider.addTarget(self, action: #selector(valueChange), for: .valueChanged)
            }
            
            @objc func valueChange() {
                valueLabel.text = "\(slider.value)"
                setNeedsLayout()
            }
            
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            override func layoutSubviews() {
                super.layoutSubviews()
                
                nameLabel.pin.left().sizeToFit()
                valueLabel.pin.after(of: nameLabel, aligned: .bottom).marginLeft(10).sizeToFit()
                slider.pin.below(of: nameLabel, aligned: .left).marginTop(10).width(frame.width).sizeToFit()
            }
            
            override func sizeThatFits(_ size: CGSize) -> CGSize {
                autoSizeThatFits(size, layoutClosure: layoutSubviews)
            }
        }
        
        let firstInsetSectionBar = Bar(title: "第一行 inset of first section", min: 16, max: 36)
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            addSubview(firstInsetSectionBar)
        }
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            firstInsetSectionBar.pin.horizontally(16).sizeToFit(.width)
        }
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            autoSizeThatFits(size, layoutClosure: layoutSubviews)
        }
    }
    
    private lazy var insetLayout: InsetLayout = InsetLayout(insetLayoutDelegate: self, sectionDecorationDelegate: self)
    private lazy var collectionView: UICollectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: insetLayout)
    
    private lazy var dataSource = {
        UICollectionViewDiffableDataSource<Section, Item>(collectionView: self.collectionView) { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? DemoCell else {
                fatalError("Should register identifier with `Cell`<DemoCell>")
            }
            cell.buildContent(indexPath)
            return cell
        }
    }()
    
    // private let controlBar: ControlBar = ControlBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        collectionView.delegate = self
        collectionView.register(DemoCell.self, forCellWithReuseIdentifier: "Cell")
        
        var snapshot = dataSource.snapshot()
        snapshot.appendSections([.one, .two, .three])
        
        let sectionOneItems: [Item] = (0 ... 2).map({ Item(indexPath: IndexPath(item: $0, section: 0)) })
        snapshot.appendItems(sectionOneItems, toSection: .one)
        
        let sectionTwoItems: [Item] = (0 ... 5).map({ Item(indexPath: IndexPath(item: $0, section: 1)) })
        snapshot.appendItems(sectionTwoItems, toSection: .two)
        
        let sectionThreeItems: [Item] = (0 ... 8).map({ Item(indexPath: IndexPath(item: $0, section: 2)) })
        snapshot.appendItems(sectionThreeItems, toSection: .three)
        
        dataSource.apply(snapshot)
        
        view.addSubview(collectionView)
        //view.addSubview(controlBar)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //controlBar.pin.bottom(44).horizontally().sizeToFit()
        //collectionView.pin.top().horizontally().above(of: controlBar, aligned: .left)
        
        collectionView.pin.all()
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    
    private func size(for contentWidth: CGFloat) -> CGSize {
        let w: CGFloat = (contentWidth / 3)
        return CGSize(width: w, height: w)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            return size(for: UIScreen.main.bounds.width - 32 - 20)
        } else if indexPath.section == 1 {
            return size(for: UIScreen.main.bounds.width - 20)
        } else {
            return size(for: UIScreen.main.bounds.width - 88 - 20)
        }
    }
    
}

extension ViewController: InsetLayoutDelegate {
    
    func inset(at section: Int) -> UIEdgeInsets {
        if section == 0 {
            return UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        } else if section == 1 {
            return UIEdgeInsets(top: 30, left: 0, bottom: 10, right: 0)
        } else {
            return UIEdgeInsets(top: 30, left: 44, bottom: 10, right: 44)
        }
    }
    
    func lineSpacing(at section: Int) -> CGFloat {
        if section == 0 {
            return 10
        } else if section == 1 {
            return 10
        } else {
            return 10
        }
    }
    
    func interitemSpacing(at section: Int) -> CGFloat {
        if section == 0 {
            return 10
        } else if section == 1 {
            return 10
        } else {
            return 10
        }
    }
}

extension ViewController: SectionDecorationDelegate {
    
    func decorationType(at section: Int) -> UICollectionReusableView.Type? {
        DemoDecorationView.self
    }
    
}


// MARK: Decoartion
final class DemoDecorationView: UICollectionReusableView {
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        if layoutAttributes.indexPath.section == 0 {
            backgroundColor = .purple
        } else if layoutAttributes.indexPath.section == 1 {
            backgroundColor = .orange
        } else {
            backgroundColor = .red
        }
        
        layer.cornerRadius = 8
    }
    
}


// MARK: Cell
final class DemoCell: UICollectionViewCell {
    
    static let colors: [UIColor] = [
        .red, .brown, .cyan, .gray, .green, .magenta, .orange
    ]
    
    private let container: UIView = UIView()
    private let largeLabel: UILabel = .init()
    private let rowLabel: UILabel = .init()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        largeLabel.font = .systemFont(ofSize: 12, weight: .medium)
        rowLabel.font = .systemFont(ofSize: 14, weight: .regular)
        
        largeLabel.textColor = .black
        rowLabel.textColor = .darkGray
        
        container.addSubview(largeLabel)
        container.addSubview(rowLabel)
        
        container.backgroundColor = .white
        container.layer.cornerRadius = 4
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = .init()
        container.layer.shadowRadius = 8
        container.layer.shadowOpacity = 0.5
        
        contentView.addSubview(container)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Should implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        container.pin.all()
        
        largeLabel.pin
            .topLeft(6)
            .sizeToFit()
        
        rowLabel.pin
            .hCenter()
            .vCenter()
            .sizeToFit()
    }
    
    func buildContent(_ indexPath: IndexPath) {
        largeLabel.text = "Section: \(indexPath.section)"
        rowLabel.text = "item: \(indexPath.item)"
        
        //container.backgroundColor = Self.colors.randomElement()
    }
    
}
