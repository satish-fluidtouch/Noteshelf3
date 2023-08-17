//
//  FTExceptionHandler.swift
//  Noteshelf
//
//  Created by Akshay on 11/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
#if !targetEnvironment(macCatalyst)
import Flurry_iOS_SDK
#endif

final class FTExceptionHandler {

    private typealias SignalHandler = @convention(c)(Int32) -> Void

    private static var uncaughtExceptionHandler : @convention(c) (_ exception: NSException) -> Void = { exception in
        #if !targetEnvironment(macCatalyst)
        Flurry.logError("Uncaught Exception", message: exception.name.rawValue, exception: exception)
        #endif
        FTCLSLog("Uncaught Exception:name \(exception.name.rawValue) description:\(exception.description)")

        if let fileHandle = fopen((FTExceptionHandler.crashFlagPath() as NSString).fileSystemRepresentation, "w") {
            vfprintf(fileHandle, "crashed", getVaList([0]));
            fclose(fileHandle)
        }
        exit(-1)
    }

    static func configure() {
        NSSetUncaughtExceptionHandler(uncaughtExceptionHandler)
        setupUncaughtSignals()
    }

    static func didCrash() -> Bool {
        if FileManager.default.fileExists(atPath: crashFlagPath()) {
            try? FileManager.default.removeItem(atPath: crashFlagPath())
            return true
        }
        return false
    }

    private static func setupUncaughtSignals()
    {
        let crashHandler:SignalHandler = { signal in
            print("Received HUP signal, reread config file")
        }
        var mySigAction : sigaction = sigaction();
        mySigAction.__sigaction_u = __sigaction_u(__sa_handler: crashHandler)
        mySigAction.sa_flags = SA_SIGINFO;

        sigemptyset(&mySigAction.sa_mask);
        sigaction(SIGQUIT, &mySigAction, nil);
        sigaction(SIGILL, &mySigAction, nil);
        sigaction(SIGTRAP, &mySigAction, nil);
        sigaction(SIGABRT, &mySigAction, nil);
        sigaction(SIGEMT, &mySigAction, nil);
        sigaction(SIGFPE, &mySigAction, nil);
        sigaction(SIGBUS, &mySigAction, nil);
        sigaction(SIGSEGV, &mySigAction, nil);
        sigaction(SIGSYS, &mySigAction, nil);
        sigaction(SIGPIPE, &mySigAction, nil);
        sigaction(SIGALRM, &mySigAction, nil);
        sigaction(SIGXCPU, &mySigAction, nil);
        sigaction(SIGXFSZ, &mySigAction, nil);
    }

    private static func crashFlagPath() -> String {
        let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).last
        return URL(fileURLWithPath: path ?? "").appendingPathComponent("crashed.log").path
    }
}
