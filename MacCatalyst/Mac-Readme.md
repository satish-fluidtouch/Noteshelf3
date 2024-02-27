## Compile for Maccatalyst

1. Change Pods Project Developer team to Fluid touch pvt ltd.

        `Pods -> Build Settings -> Developer team -> set to Fluid touch pvt ltd.`
        
2. Frameworks under `Noteshelf Project -> Noteshelf Target -> General -> Frameworks…`  to be changed for iOS only
    - AseetsLibrary
    - FTMetrics
    - libGPUimage.a
    - Myscript libraries
    - OpenCV
    - OpenGLES

3. Under `Pods Project -> pods-noteshelf target -> Dependencies` to be changed for iOS only
    - FirebasePhoneAuthUI
    - FirebaseUI
    - ZendeskCommonSDK
    - ZendeskCoreSDK
    - ZendeskMessagingAPISDK
    - ZendeskMessagingSDK
    - ZendeskSDKConfigurationSDK
    - ZendeskSupportProvidersSDK
    - ZendeskSupportSDK

4. Under `Noteshelf project -> Noteshelf target -> Build Phase -> [CP] Embed Pods Frameworks` make sure to have

        if [[ "$PLATFORM_NAME" = "macosx" ]]; then
            "${SRCROOT}/MacCatalyst/Noteshelf-maccatalyst-frameworks.sh"
        else
            "${PODS_ROOT}/Target Support Files/Pods-Noteshelf3/Pods-Noteshelf3-frameworks.sh"
        fi

5. Under `Noteshelf project -> Noteshelf target -> Build Phase -> [CP] Copy Pods Resources` make sure to have

        if [[ "$PLATFORM_NAME" != "macosx" ]]; then
            "${PODS_ROOT}/Target Support Files/Pods-Noteshelf/Pods-Noteshelf-resources.sh"
        fi
    
6. In order to archive the build please do the below steps.
    1. Select `Pods -> Boring-SSL -> BuildPhase -> search for ssl.h` and move from `project` to `public`.
    2.  Select `Pods -> gprc-core -> BuildPahse -> search for bytebuffer.h`, select the second result and move from `project` to `public`.

7. Before appstore compile make sure Signing certificate to "sign to run locally" for below bundles under signing & certifcates tab
    1. FBSDKCoreKit-FacebookSDKStrings
    2. FirebaseAnonymousAuthUI-FirebaseAnonymousAuthUI
    3. FirebaseAuthUI-FirebaseAuthUI
    4. FirebaseEmailAuthUI-FirebaseEmailAuthUI
    5. FirebaseFacebookAuthUI-FirebaseFacebookAuthUI
    6. FirebaseGoogleAuthUI-FirebaseGoogleAuthUI
    7. FirebaseOAuthUI-FirebaseOAuthUI
    8. GoogleSignIn-GoogleSignIn
    9. gRPC-C++-gRPCCertificates-Cpp


/////////
Open Ai Used Key:
Main Key: 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
Placeholder: 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
/////
