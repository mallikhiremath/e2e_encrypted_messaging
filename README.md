# End To End encrypted messaging App

## Secure Messaging App
The vast majority of messaging apps used globally today for communication between users or in group settings use a simple standard SSL mechanism between the user's client device and server.
For example, the popular apps like Facebook Messenger, Snapchat, Instagram, Twitter etc do not do end-to-end encryption.
In these apps, the private messages could be potentially read by third parties, organizations behind the apps.
At times Government can inquire the hosting companies to release the message history for a given user or for a communication channel in a group.
 
On the other hand there are handful of Chat messaging applications such as WhatsApp, Signal do either a limited or full end-to-end encryption.
The end-to-end encryption measure prohibits anyone from seeing the contents of the message except for sender the intended recipients.
The best secure chat applications are not only becoming more sought-after, they are also becoming crucial in today's cyber security aware world!.

Here we have put our best efforts to create a secure end to end encryption messaging system using the Flutter SDK and Stream SDK.

### We selected Flutter SDK for developing our application because of the following reasons:
1. Apps built with Flutter can run on multiple operating Systems.
2. Flutter reduces the amount of code required, reduces time to market.
3. For developers it combines ease of development.

### Installing Flutter:
https://docs.flutter.dev/get-started/install
A few Flutter resources:
- [Lab: Write Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Please make sure you are using the latest version of Flutter from the stable channel:
```dart
flutter channel stable
flutter upgrade
```

### For the backend support we selected stream.io
Add stream_chat_flutter to your dependencies, to do that just open pubspec.yaml and add it inside the dependencies section.

```dart
dependencies:
  flutter:
    sdk: flutter

  stream_chat_flutter: ^3.1.1
```

In this application, we will be using the `stream_chat_flutter` package which contains UI components for messaging.
Additionally `stream_chat_flutter_core` provides bare-bones implementation with logic and builders for UI.
For the most possible control, the `stream_chat` package allows access to the low-level client.

The UI widgets uses the StreamChat or StreamChannel to manage the state and communication between our app and the Stream Chat API.

### Flutter Chat SDK Features
1. Show participant watcher counts
2. Read state for all users in channel
3. Individual read state
4. User presence/online indicator
5. User's read states
6. Read indicators
7. Push notifications
8. GIF support
9. Light/dark themes
10. Style customization
11. UI customization
12. Offline support
13. Threads
14. Slash commands
15. Markdown messages formatting


### Flutter Advantages mind-map:

![img.png](images/Flutter_Intro.png)


### About Stream's Flutter Chat SDK:
![img.png](images/StreamSDKStuff.png)


### E2E Secure Messaging

![img.png](images/E2E_Secure_Messaging.png)

### Web Cryptography
![img.png](images/Web_Cryptography_API.png)
