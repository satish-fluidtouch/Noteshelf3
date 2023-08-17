//
//  NSError_Display.swift
//  Noteshelf
//
//  Created by Amar on 14/11/16.
//
//

import Foundation

extension NSError
{
    @objc func showAlert(from fromViewController: UIViewController?)
    {
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        if(!Thread.current.isMainThread) {
            DispatchQueue.main.async {
                self.showAlert(from: fromViewController);
            }
            return;
        }
        var title : String?
        var message : String?
        
        let codeValue = Int32(self.code);
        switch (codeValue)
        {
        case CFNetworkErrors.cfurlErrorCannotConnectToHost.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorCannotFindHost.rawValue:
            title = NSLocalizedString("ConnectionFailed", comment:"Connection Failed");
            message = NSLocalizedString("CouldNotConnectToServer", comment:"Could not connect to server. Please try again later.");
        case CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue:
            title = NSLocalizedString("ConnectionFailed", comment:"Connection Failed");
            message = NSLocalizedString("CheckYourInternetConnection", comment:"Please check your Internet connection and try again later.");
        case CFNetworkErrors.cfurlErrorTimedOut.rawValue:
            title = NSLocalizedString("ConnectionFailed", comment:"Connection Failed");
            message = NSLocalizedString("ServerTakingTooLong", comment:"Server is taking too long to respond. Please try again later.");
        case CFNetworkErrors.cfurlErrorBadServerResponse.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorZeroByteResource.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorCannotDecodeRawData.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorCannotDecodeContentData.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorCannotParseResponse.rawValue:
            title = NSLocalizedString("ErrorConnecting", comment:"Error Connecting");
            message = NSLocalizedString("BadResponseFromServer", comment:"Bad response from server. Please try again later.");
        case CFNetworkErrors.cfurlErrorUnknown.rawValue:
        fallthrough// all other CFURLConnection and CFURLProtocol errors
        case CFNetworkErrors.cfurlErrorCancelled.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorBadURL.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorUnsupportedURL.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorNetworkConnectionLost.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorDNSLookupFailed.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorHTTPTooManyRedirects.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorResourceUnavailable.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorRedirectToNonExistentLocation.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorUserCancelledAuthentication.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorUserAuthenticationRequired.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorInternationalRoamingOff.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorCallIsActive.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorDataNotAllowed.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorRequestBodyStreamExhausted.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorFileDoesNotExist.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorFileIsDirectory.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorNoPermissionsToReadFile.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorDataLengthExceedsMaximum.rawValue:
            title = NSLocalizedString("ErrorConnecting", comment:"Error Connecting");
            message = NSLocalizedString("ProblemConnectingToServer", comment:"Problem connecting to server. Please try again later.");
        default:
            title = NSLocalizedString("Error", comment:"Error");
            message = self.localizedDescription;
        }
        
        //***************************************************
        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertController.Style.alert);

        let action = UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertAction.Style.cancel, handler: nil);
        alertController.addAction(action);

        fromViewController?.present(alertController, animated: true, completion: nil);
        #endif
    }
    
    func errorDescription() -> String
    {
        var message : String?
        let codeValue = Int32(self.code);
        switch (codeValue)
        {
        case CFNetworkErrors.cfurlErrorCannotConnectToHost.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorCannotFindHost.rawValue:
            message = NSLocalizedString("CouldNotConnectToServer", comment:"Could not connect to server. Please try again later.");
        case CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue:
            message = NSLocalizedString("CheckYourInternetConnection", comment:"Please check your Internet connection and try again later.");
        case CFNetworkErrors.cfurlErrorTimedOut.rawValue:
            message = NSLocalizedString("ServerTakingTooLong", comment:"Server is taking too long to respond. Please try again later.");
        case CFNetworkErrors.cfurlErrorBadServerResponse.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorZeroByteResource.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorCannotDecodeRawData.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorCannotDecodeContentData.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorCannotParseResponse.rawValue:
            message = NSLocalizedString("BadResponseFromServer", comment:"Bad response from server. Please try again later.");
        case CFNetworkErrors.cfurlErrorUnknown.rawValue:
        fallthrough// all other CFURLConnection and CFURLProtocol errors
        case CFNetworkErrors.cfurlErrorCancelled.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorBadURL.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorUnsupportedURL.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorNetworkConnectionLost.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorDNSLookupFailed.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorHTTPTooManyRedirects.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorResourceUnavailable.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorRedirectToNonExistentLocation.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorUserCancelledAuthentication.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorUserAuthenticationRequired.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorInternationalRoamingOff.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorCallIsActive.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorDataNotAllowed.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorRequestBodyStreamExhausted.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorFileDoesNotExist.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorFileIsDirectory.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorNoPermissionsToReadFile.rawValue:
            fallthrough
        case CFNetworkErrors.cfurlErrorDataLengthExceedsMaximum.rawValue:
            message = NSLocalizedString("ProblemConnectingToServer", comment:"Problem connecting to server. Please try again later.");
        default:
            message = self.localizedDescription;
        }
        return message!;
    }
    
    @objc func dropboxFriendlyMessageErrorDescription() -> String
    {
        var friendlyMessage = self.localizedDescription;
        
        let nsError = self;
        
        let domain = nsError.domain;
        let errorCode = nsError.code;
        
        if(domain == "dropbox.com") {
            switch errorCode {
            case 507:
                friendlyMessage = NSLocalizedString("DropbBoxBackupStorageFullErrorMsg", comment: "Your dropbox storage is full.");
            default:
                break;
            }
        }
        return friendlyMessage;
    }
    
    var isDownloadCancelError : Bool {
        if self.domain == "FTNSDownloadItem", self.code == 100 {
            return true;
        }
        return false;
    }
}
