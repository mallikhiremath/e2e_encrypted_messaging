import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'appe2ee.dart';

/// This is the main class that would launch the application.
/// This class makes use of stream chat flutter sdk (and client)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Create an instance of [StreamChatClient] passing the key obtained from Stream
  /// project dashboard.
  final client = StreamChatClient(
    'm7b7hqpfuke8',
    logLevel: Level.INFO,
  );

  /// Initialize the public private key:

  await AppE2EE().generateKeysIfNotPresent();
  Map<String, dynamic>? publicKeyJwk = AppE2EE().publicKeyJwk;

  /// Set the current user. In a production scenario, this should be done using
  /// a backend to generate a user token using our server SDK.
  /// Please see the following for more information:
  /// https://getstream.io/chat/docs/flutter-dart/tokens_and_authentication/?language=dart
  await client.connectUser(
    User(id: 'MallikH', name: 'Mallik Hiremath', extraData: {
      'image': 'https://picsum.photos/id/1005/200/300',
      'publicKey': publicKeyJwk
    }),
    client.devToken('MallikH').rawValue,
  );

  // await client.connectUser(
  //   User(id: 'SatyaS', name: 'Satya Salvi', extraData: {
  //     'image': 'https://picsum.photos/id/1005/200/300',
  //     'publicKey': publicKeyJwk
  //   }),
  //   client.devToken('SatyaS').rawValue,
  // );

  /// Creates a channel using the type `messaging` and `flutterdevs`.
  /// Channels are containers for holding messages between different members. To
  /// learn more about channels and some of our predefined types, checkout our
  /// our channel docs: https://getstream.io/chat/docs/flutter-dart/creating_channels/?language=dart
  ///

  final channel = client.channel(
    'messaging',
    id: 'food-channel',
    extraData: {
      "name": "Food Chat",
      "image": "http://bit.ly/2O35mws",
      "members": ["MallikH", "SatyaS"],
    },
  );

  // final userList = await client.queryUsers(
  //   filter: Filter.in_( "id", const ['MallikH']),
  // );

  final userList = await client.queryUsers(
    filter: Filter.in_("id", const ['SatyaS']),
  );

  User user1 = userList.users.first;
  print('user1  details = $user1');

  Map<String, Object?> extraData = user1.extraData;
  print('the extraData = $extraData');
  if (extraData.isNotEmpty) {
    var otherPublicStr = extraData["publicKey"] as Map<String, dynamic>;
    print('the other publickeyStr = $otherPublicStr');
    await AppE2EE().deriveBitsFromPublicKey(otherPublicStr);
  }

  /// `.watch()` is used to create and listen to the channel for updates. If the
  /// channel already exists, it will simply listen for new events.
  await channel.watch();
  runApp(MyApp(client: client));
}

/// This class represents the Messaging App
class MyApp extends StatelessWidget {
  /// To initialize this example, an instance of [client] and [channel] is required.
  const MyApp({Key? key, required this.client}) : super(key: key);

  /// Instance of [StreamChatClient] we created earlier. This contains information about
  /// our application and connection state.
  final StreamChatClient client;

  @override
  Widget build(BuildContext context) {
    final themeData = ThemeData(primarySwatch: Colors.green);
    final defaultTheme = StreamChatThemeData.fromTheme(themeData);
    final colorTheme = defaultTheme.colorTheme;
    final customTheme = defaultTheme.merge(StreamChatThemeData(
      channelPreviewTheme: ChannelPreviewThemeData(
        avatarTheme: AvatarThemeData(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      otherMessageTheme: MessageThemeData(
        messageBackgroundColor: colorTheme.textHighEmphasis,
        messageTextStyle: TextStyle(
          color: colorTheme.barsBg,
        ),
        avatarTheme: AvatarThemeData(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ));

    return MaterialApp(
      theme: themeData,
      builder: (context, child) => StreamChat(
        client: client,
        streamChatThemeData: customTheme,
        child: child,
      ),
      home: const ChannelListPage(),
    );
  }
}

/// Displays the list of messages inside the channel
class ChannelListPage extends StatelessWidget {
  const ChannelListPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChannelsBloc(
        child: ChannelListView(
          filter: Filter.in_(
            'members',
            [StreamChat.of(context).currentUser!.id],
          ),
          channelPreviewBuilder: _channelPreviewBuilder,
          sort: [SortOption('last_message_at')],
          limit: 20,
          channelWidget: const ChannelPage(),
        ),
      ),
    );
  }

  Widget _channelPreviewBuilder(BuildContext context, Channel channel) {
    final lastMessage = channel.state?.messages.reversed.firstWhere(
      (message) => !message.isDeleted,
    );

    final subtitle = lastMessage == null ? 'nothing yet' : lastMessage.text!;
    final opacity = (channel.state?.unreadCount ?? 0) > 0 ? 1.0 : 0.5;

    final theme = StreamChatTheme.of(context);

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StreamChannel(
              channel: channel,
              child: const ChannelPage(),
            ),
          ),
        );
      },
      leading: ChannelAvatar(
        channel: channel,
      ),
      title: ChannelName(
        textStyle: theme.channelPreviewTheme.titleStyle!.copyWith(
          color: theme.colorTheme.textHighEmphasis.withOpacity(opacity),
        ),
      ),
      subtitle: Text(subtitle),
      trailing: channel.state!.unreadCount > 0
          ? CircleAvatar(
              radius: 10,
              child: Text(channel.state!.unreadCount.toString()),
            )
          : const SizedBox(),
    );
  }
}

/// This class represents the ChannelPage
/// provides the necessary support to display the channels
/// on the ChannelPage
class ChannelPage extends StatelessWidget {
  const ChannelPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ChannelHeader(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: MessageListView(
              messageBuilder: _messageBuilder,
              threadBuilder: (_, parentMessage) => ThreadPage(
                parent: parentMessage,
              ),
            ),
          ),
          MessageInput(
            disableAttachments: true,
            preMessageSending: (Message message) async {
              String encryptedText = await AppE2EE().encrypt(message.text);
              Message encryptedMessage = message.copyWith(text: encryptedText);
              return encryptedMessage;
            },
          ),
        ],
      ),
    );
  }

  Widget _messageBuilder(
    BuildContext context,
    MessageDetails details,
    List<Message> messages,
    MessageWidget defaultMessageWidget,
  ) {
    Message message = details.message;
    final isCurrentUser = StreamChat.of(context).user!.id == message.user!.id;
    final textAlign = isCurrentUser ? TextAlign.right : TextAlign.left;
    final color = isCurrentUser ? Colors.blueGrey : Colors.blue;

    return FutureBuilder<String>(
      future: AppE2EE().decrypt(message.text), // a Future<String> or null
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
          default:
            if (snapshot.hasError)
              return Text('Error: ${snapshot.error}');
            else {
              return Padding(
                padding: EdgeInsets.all(5.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: color, width: 1),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(5.0),
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      snapshot.data ?? '',
                      textAlign: textAlign,
                    ),
                  ),
                ),
              );
            }
        }
      },
    );
  }
}

/// This class provides the necessary support for the Threaded messages
class ThreadPage extends StatelessWidget {
  const ThreadPage({
    Key? key,
    this.parent,
  }) : super(key: key);

  final Message? parent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ThreadHeader(
        parent: parent!,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: MessageListView(
              parentMessage: parent,
            ),
          ),
          MessageInput(
            disableAttachments: true,
            preMessageSending: (Message message) async {
              String encryptedText = await AppE2EE().encrypt(message.text);
              Message encryptedMessage = message.copyWith(text: encryptedText);
              return encryptedMessage;
            },
          ),
        ],
      ),
    );
  }
}
