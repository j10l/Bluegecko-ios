//
//  EnvironmentDemoViewController.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SVProgressHUD

class EnvironmentDemoViewController: DemoViewController, EnvironmentDemoInteractionOutput, UICollectionViewDelegate, SILThunderboardConnectedDeviceBar, ConnectedDeviceDelegate {
    
    var connectedDeviceView: ConnectedDeviceBarView?
    var connectedDeviceBarHeight: CGFloat = 70.0

    @IBOutlet var collectionView: UICollectionView!
    var interaction: EnvironmentDemoInteraction?
    var deviceConnector: DeviceConnection?
    
    fileprivate var dataSource = EnvironmentDemoCollectionViewDataSource()
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 7)
        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        
        dataSource.activeViewModels.debounce(.milliseconds(500), scheduler: MainScheduler.instance).bind(to: collectionView.rx.items(cellIdentifier: EnvironmentCollectionViewCell.cellIdentifier, cellType: EnvironmentCollectionViewCell.self)){(_, element, cell) in
            cell.configureCell(with: element)
        }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected.withLatestFrom(dataSource.activeViewModels).debug().subscribe(onNext: { [weak self] viewModels in
            guard let strongSelf = self,
                let indexPath = strongSelf.collectionView.indexPathsForSelectedItems?.first,
                indexPath.item < viewModels.count else {
                    return
            }
            let viewModel = viewModels[indexPath.item]
            if viewModel.capability == .hallEffectState {
                if strongSelf.dataSource.currentHallEffectState == .tamper {
                    strongSelf.interaction?.resetTamperState()
                } else {
                    print("Current state is not tamper")
                }
            }
        }).disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(forName: SettingsViewController.temperatureSettingUpdated, object: nil, queue: nil) { (notification) in
            self.dataSource.update()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.interaction?.updateView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        deviceConnector?.disconnectAllDevices()
    }
    
    @IBAction func backButton() {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - EnvironmentDemoInteractionOutput

    func updatedEnvironmentData(_ data: EnvironmentData, capabilities: Set<DeviceCapability>) {
        dataSource.updateData(data, capabilities: capabilities)
    }
    
    @IBAction func settingsButtonPressed() {
        let settings = UIStoryboard(name: "SettingsViewController", bundle: nil).instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsNavigationController
        self.navigationController?.present(settings, animated: true, completion: nil)
    }
}
