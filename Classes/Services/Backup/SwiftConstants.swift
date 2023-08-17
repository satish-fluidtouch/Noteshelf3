public let FTBackUpGUIDKey = "GUID"
public let FTBackUpIsDirtyKey = "isDirty"
public let FTBackUpLastUpdatedKey = "lastUpdated"
public let FTBackUpPackagePathKey = "packagePath"
public let FTBackUpLastBackedUpDateKey = "lastBackupDate"
public let FTBackUpErrorDescriptionKey = "errorDescription"

public let FTBackUpWillBeginPublishNotificationFormat = "PublishWillBeginNotification_%@"
public let FTBackUpDidCompletePublishNotificationFormat = "PublishCompleteNotification_%@"
public let FTBackUpDidCancelledPublishNotificationFormat = "PublishCancelledNotification_%@"
public let FTBackUpDidCompletePublishWithErrorNotificationFormat = "PublishCompleteWithErrorNotification_%@"
public let FTBackUpPublishProgressNotificationFormat = "PublishProgressNotification_%@"

protocol FTBaseCloudManagerDelegate: NSObjectProtocol {
    func cloudBackUpManager(_ cloudManager: FTCloudBackupPublisher, didCompleteWithError error: NSError?)
    func didCancelCloudBackUpManager(_ cloudManager: FTCloudBackupPublisher)
}
