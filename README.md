# PubNub Chat Components for iOS

Chat components provide easy-to-use building blocks to create iOS chat applications, for use cases like live event messaging, telemedicine, and service desk support.

Our iOS component library provides chat features like direct and group messaging, typing indicators, presence, and reactions.  You don't need to implement a data source by yourself and go through the complexity of designing the architecture of a realtime network. Instead, use our components, predefined repositories, and view models to create custom apps for a wide range of use cases.

## Features

* **User and Channel Metadata**: add additional information about the users, channels, and their memberships (and store it locally for offline use)
* **Subscriptions**: subscribe to user channels automatically
* **Messages**: publish and display new and historical text messages
* **Presence**: get currently active users, observe their state, and notify about changes
* **Typing Indicators**: display notifications that users are typing
* **Persistent Data Storage**: store messages, channels, and users locally
* **Paging**: pull new data only when you need it
* **UIKit Views and Patterns**: use your existing UIKit code to build native UI

## Available components

* [ChannelList](/docs/chat/components/ios/ui-components-ios#channellist)
* [MemberList](/docs/chat/components/ios/ui-components-ios#memberlist)
* [MessageList](/docs/chat/components/ios/ui-components-ios#messagelist)
* [MessageInput](/docs/chat/components/ios/ui-components-ios#messageinput)
* [ChatProvider](/docs/chat/components/ios/chat-provider-ios)

## Related documentation

* [Swift SDK Documentation](/docs/sdks/swift)
* [Core Data Documentation](https://developer.apple.com/documentation/coredata)
* [UIKit Documentation](https://developer.apple.com/documentation/uikit/)

## Getting Started

This page outlines the steps to follow to set up a sample application with PubNub Chat Components for iOS. It covers the basics of integrating PubNub in your application, setting up the default chat components, and displaying an empty component when the app is started.

## Prerequisites

| Name | Requirement |
| :--- | :------ |
| [Xcode](https://developer.apple.com/xcode/resources/) | >= 13.0 |
| Platform | iOS, iPad, macOS |
| Language | >= Swift 5 |
| UI Framework | UIKit |
| [PubNub Swift SDK](https://github.com/pubnub/swift) | >= 4.1.0 |

## Create a PubNub account

1. Sign in or set up an account on the [Admin Portal](https://dashboard.pubnub.com/). Create an app to get the keys you will need to use in your application.

1. When you create a new app, the first set of keys is generated automatically, but a single app can have as many keysets as you like. We recommend that you create separate keysets for production and test environments.

    :::info Additional features
    Depending on your use case, you may want your app to have some PubNub features, such as Presence, Storage and Playback (including correct Retention), or Objects. To use them, you must first enable them on your Admin Portal keysets. If you decide to use Objects, be sure to select a geographic region corresponding to most users of your application.
    :::

## Create a new project for your app

1. Install and open [Xcode](https://developer.apple.com/xcode/resources/).

1. In Xcode, click **Create a new Xcode project** in the **Welcome to Xcode** window or select **File** > **New** > **Project** from the menu.

1. Follow the prompts to select the appropriate application. Enter both the name and the bundle ID in the desired app.

For any additional questions, refer to [Apple documentation](https://developer.apple.com/documentation/xcode/creating-an-xcode-project-for-an-app).

## Install chat components

1. Inside your Xcode project, select **File** > **Add Packages...**, and enter the project repository URL.

1. If your GitHub account is added to Xcode's preferences, you can search for `PubNubChatComponents` in the **Github** section. If it's not added, search using the package URL `https://github.com/pubnub/apple-chat-components`.

1. After the package details load, click the **Add Package** button in the lower right corner.

For any additional questions, refer to [Apple documentation](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app).

## Work with chat components

The first required step is to call `ChatProvider`, which initializes all the data components. These components are responsible for providing data to UI, setting the default theme, and communicating with the PubNub service. The best way to achieve it is by modifying the application theme functionality.

1. Open `SceneDelegate` and import `PubNub`, `PubNubChat`, and `PubNubChatComponents`.

    ```swift
    import PubNub
    import PubNubChat
    import PubNubChatComponents
    ```

1. Declare a `ChatProvider` instance property that is populated by the initial `Scene` in the following steps.

    ```swift
    class SceneDelegate: UIResponder, UIWindowSceneDelegate {

        var window: UIWindow?
        var chatProvider: PubNubChatProvider?
    ...
    ```

1. Complete the PubNub Configuration. To do that, use your Publish and Subscribe Keys from your PubNub account dashboard on the Admin Portal.

    ```swift
    var pubnubConfig = PubNubConfiguration(
          publishKey: "pub-c-key", subscribeKey: "sub-c-key"
    )
    ```

    You can configure the UUID to associate a sender/current user with the PubNub messages. You can get it from a previously cached entry.

    ```swift
    pubnubConfig.uuid = PubNubChatProvider.cachedSenderID ?? "uuid-of-current-user"
    ```

1. Create `ChatProvider`. This object is used to facilitate the majority of the functionality provided by PubNub Chat Components for iOS.

    ```swift
    self.chatProvider = PubNubChatProvider(pubnubConfiguration: pubnubConfig)
    ```

    For more information, refer to the [ChatProvider](/docs/chat/components/ios/chat-provider-ios) section.

1. Create a default `ChannelListViewModel` that is used to display all the channels that are associated with the current user.

    ```swift
    guard let defaultChannelViewModel = chatProvider?
          .senderMembershipsChanneListComponentViewModel() else { return }

    // Create navigation structure
    let componentNavigation = UINavigationController()
    componentNavigation.viewControllers = [defaultChannelViewModel.configuredComponentView()]
    ```

1. Set the component as the root view controller and display the window.

    ```swift
    window.rootViewController = componentNavigation
    self.window = window
    window.makeKeyAndVisible()
    ```

    At the end, `SceneDelegate` should resemble the following:

    ```swift
    import UIKit

    import PubNub
    import PubNubChat
    import PubNubChatComponents

    class SceneDelegate: UIResponder, UIWindowSceneDelegate {

      var window: UIWindow?
      var chatProvider: PubNubChatProvider?

      func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
      ) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)

        if chatProvider == nil {
          var pubnubConfig = PubNubConfiguration(publishKey: "pub-c-key", subscribeKey: "sub-c-key")
          pubnubConfig.uuid = PubNubChatProvider.cachedCurrentUserId ?? "uuid-of-current-user"

          chatProvider = PubNubChatProvider(
            pubnubConfiguration: pubnubConfig
          )
        }

        // Create the default Channel List Component
        guard let defaultChannelViewModel = chatProvider?.senderMembershipsChanneListComponentViewModel() else {
          preconditionFailure("Could not create intial view")
        }

        // Create navigation structure
        let navigation = UINavigationController()
        navigation.viewControllers = [defaultChannelViewModel.configuredComponentView()]

        // Set the component as the root view controller
        window.rootViewController = navigation
        self.window = window
        window.makeKeyAndVisible()
      }
    }
    ```


## Support

If you **need help** or have a **general question**, contact <support@pubnub.com>.

## License

The PubNub Swift SDK is released under the MIT license.
[See LICENSE](https://github.com/pubnub/swift/blob/master/LICENSE) for details.
