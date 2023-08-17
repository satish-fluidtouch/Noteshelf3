//
//  FTBackgroundTaskManager.swift
//  Noteshelf
//
//  Created by Naidu on 21/12/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
//FTBackgroundTaskProcessor
class FTBackgroundTaskManager: NSObject {
    internal var taskList: [FTBackgroundTask] = []
    internal var processor: FTBackgroundTaskProcessor!

    private lazy var dispatchQueue:DispatchQueue = {
        return DispatchQueue.init(label: self.dispatchQueueID(), qos: DispatchQoS.background, attributes: [], autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)
    }();
    
    deinit {
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }
    
    override init() {
        super.init()
        self.processor = self.getTaskProcessor()
    }
    
    func addBackgroundTask(_ newTask: FTBackgroundTask){
        objc_sync_enter(self);
        self.taskList.append(newTask)
        if (self.processor.canAcceptNewTask == false){
            newTask.onStatusChange?(FTBackgroundTaskStatus.waiting)
        }
        objc_sync_exit(self);
        self.executeNextTask()
    }
    
    private func executeNextTask(){
        if (self.processor.canAcceptNewTask == false) {
            return
        }
        
        self.dispatchQueue.async {
            var taskToExe : FTBackgroundTask?;
            objc_sync_enter(self);
            if !self.taskList.isEmpty {
                taskToExe = self.taskList.removeFirst()
            }
            objc_sync_exit(self);
            if let task = taskToExe {
                if(self.canExecuteTask(task) == false) {
                    self.executeNextTask()
                    return
                }
                task.onStatusChange?(FTBackgroundTaskStatus.inProgress)
                self.processor.startTask(task) {[weak self] in
                    task.onStatusChange?(FTBackgroundTaskStatus.finished)
                    self?.executeNextTask()
                }
            }
        }
    }
    
    internal func dispatchQueueID() -> String{
        assert(false, "Subclass should override")
        return "com.fluidtouch.default"
    }
    
    internal func getTaskProcessor() -> FTBackgroundTaskProcessor?{
        assert(false, "Subclass should override")
        return nil
    }
    
    internal func canExecuteTask(_ task: FTBackgroundTask) -> Bool{
        assert(false, "Subclass should override")
        return false
    }
}
