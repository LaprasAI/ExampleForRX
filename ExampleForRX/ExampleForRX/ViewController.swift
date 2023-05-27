//
//  ViewController.swift
//  ExampleForRX
//
//  Created by Ian Li on 2023/5/25.
//

import UIKit
import SnapKit
import RxSwift
import RxRelay
import RxCocoa
import Factory

//MARK: - View

class ViewController: UIViewController {
    
    let viewModel: ViewControllerViewModel = ViewControllerViewModel()
    var disposdeBag: DisposeBag = DisposeBag()
    
    let numberLabel: NumberLabel = NumberLabel()
    
    let addButton: UIButton = {
        let button = UIButton()
        button.setTitle("ADD", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.setTitleColor(.gray, for: .disabled)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupViews()
        self.bindViewModel()
    }

    func setupViews() {
        self.view.backgroundColor = .systemBackground
        self.view.addSubview(self.numberLabel)
        self.numberLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(100)
        }
        self.view.addSubview(self.addButton)
        self.addButton.snp.makeConstraints { make in
            make.top.equalTo(self.numberLabel.snp.bottom)
            make.centerX.equalTo(self.numberLabel.snp.centerX)
            make.size.equalTo(self.numberLabel.snp.size)
        }
    }
    
    func bindViewModel() {
        let input = ViewControllerViewModel.Input(buttonTap: self.addButton.rx.tap)
        let output = self.viewModel.transform(from: input)
        output.numberUpdate.bind(to: self.numberLabel.rx.updateNumber).disposed(by: self.disposdeBag)
        output.buttonEnable.bind(to: self.addButton.rx.isEnabled).disposed(by: self.disposdeBag)
    }
}

class NumberLabel: UIView {
    let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        return label
    }()
    
    init() {
        super.init(frame: .zero)
        self.addSubview(self.numberLabel)
        self.numberLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func changeText(to string: String) {
        self.numberLabel.text = string
    }
    
    func changeTextColor(to color: UIColor) {
        self.numberLabel.textColor = color
    }
}

fileprivate extension Reactive where Base: NumberLabel {
    var updateNumber: Binder<Int> {
        Binder(self.base, scheduler: MainScheduler.instance) { view, number in
            view.changeText(to: String(number))
            if number > 5 {
                view.changeTextColor(to: .red)
            } else {
                view.changeTextColor(to: .label)
            }
        }
    }
}

//MARK: - ViewModel

protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    func transform(from input: Input) -> Output
}

class ViewControllerViewModel: ViewModelType {
    struct Input {
        let buttonTap: ControlEvent<Void>
    }
    
    struct Output {
        let numberUpdate: BehaviorRelay<Int>
        let buttonEnable: PublishRelay<Bool>
    }
    
    // MARK: Dependency Injection
    @Injected(\.viewControllerModel) var model: ViewControllerModel
    
    var disposeBag: DisposeBag = DisposeBag()
    
    func transform(from input: Input) -> Output {
        let numberUpdate: BehaviorRelay<Int> = BehaviorRelay(value: self.model.currentNumber)
        let buttonEnable: PublishRelay<Bool> = PublishRelay()
        
        // MARK: Bussiness logic
        input.buttonTap.subscribe { _ in
            self.numberIncrease()
            numberUpdate.accept(self.model.currentNumber)
            if self.model.currentNumber == 10 {
                buttonEnable.accept(false)
            }
        }.disposed(by: self.disposeBag)
        
        return Output(numberUpdate: numberUpdate, buttonEnable: buttonEnable)
    }
    
    func numberIncrease(by n: Int = 1) {
        self.model.currentNumber += n
    }
}

// MARK: - Model

fileprivate extension Container {
    var viewControllerModel: Factory<ViewControllerModel> {
        Factory(self) {
            ViewControllerModel()
        }
    }
}

struct ViewControllerModel {
    var currentNumber: Int = 0
}
