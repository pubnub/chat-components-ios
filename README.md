# PubNub Chat Components for iOS

Chat components provide easy-to-use building blocks to create iOS chat applications, for use cases like live event messaging, telemedicine, and service desk support.

Our iOS component library provides chat features like direct and group messaging, typing indicators, presence, and reactions.  You don't need to implement a data source by yourself and go through the complexity of designing the architecture of a realtime network. Instead, use our components, predefined repositories, and view models to create custom apps for a wide range of use cases.

## Features

* **User and Channel Metadata**: Add additional information about the users, channels, and their memberships (and store it locally for offline use)
* **Subscriptions**: Subscribe to user channels automatically
* **Messages**: Publish and display new and historical text messages
* **Presence**: Get currently active users, observe their state, and notify about changes
* **Typing Indicators**: Display notifications that users are typing
* **Persistent Data Storage**: Store messages, channels, and users locally
* **Paging**: Pull new data only when you need it
* **UIKit Views and Patterns**: Use your existing UIKit code to build native UI

## Available components

* [ChannelList](https://www.pubnub.com//docs/chat/components/ios/ui-components#channellist)
* [MemberList](https://www.pubnub.com//docs/chat/components/ios/ui-components#memberlist)
* [MessageList](https://www.pubnub.com//docs/chat/components/ios/ui-components#messagelist)
* [MessageInput](https://www.pubnub.com//docs/chat/components/ios/ui-components#messageinput)
* [ChatProvider](https://www.pubnub.com//docs/chat/components/ios/chat-provider)

## Prerequisites

| Name | Requirement |
| :--- | :------ |
| [Xcode](https://developer.apple.com/xcode/resources/) | >= 13.0 |
| Platform | iOS, iPad, macOS |
| Language | >= Swift 5 |
| UI Framework | UIKit |
| [PubNub Swift SDK](https://github.com/pubnub/swift) | >= 4.1.2 |
## Usage

### Install chat components

1. Inside your Xcode project, select **File** > **Add Packages...**, and enter the project repository URL.

1. If your GitHub account is added to Xcode's preferences, you can search for `PubNubChatComponents` in the **Github** section. If it's not added, search using the package URL `https://github.com/pubnub/chat-components-ios`.

1. After the package details load, click the **Add Package** button in the lower right corner.

For any additional questions, refer to [Apple documentation](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app).
### Test sample apps

Explore [sample apps](https://github.com/pubnub/chat-components-ios-examples/blob/master/README.md) that are built using chat components.

Follow the steps in the [Getting Started guide](https://www.pubnub.com/docs/chat/components/ios) to set up a sample chat app and send your first message.

## Related documentation

* [PubNub Chat Components for iOS Documentation](https://www.pubnub.com/docs/chat/components/ios)
* [Swift SDK Documentation](https://www.pubnub.com/docs/sdks/swift)
* [Core Data Documentation](https://developer.apple.com/documentation/coredata)
* [UIKit Documentation](https://developer.apple.com/documentation/uikit/)

## Support

If you need help or have a general question, [contact support](mailto:support@pubnub.com).

## License

PubNub Chat Components for iOS is released under the MIT license.
[See LICENSE](https://github.com/pubnub/chat-components-ios/blob/master/LICENSE) for details.
