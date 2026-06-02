// import 'dart:convert';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
//
// class SignalingController {
//   final String selfId;
//   WebSocketChannel? _channel;
//   Function()? onCallAccepted;
//   Function()? onRemoteHangup;
//
//   SignalingController({required this.selfId});
//
//   void connect(String url) {
//     _channel = WebSocketChannel.connect(Uri.parse("$url?user_id=$selfId"));
//
//     _channel!.stream.listen((message) {
//       final data = jsonDecode(message);
//
//       switch (data['type']) {
//         case 'answer':
//         // The other person answered! Trigger your UI timer.
//           if (onCallAccepted != null) onCallAccepted!();
//           break;
//         case 'hangup':
//           if (onRemoteHangup != null) onRemoteHangup!();
//           break;
//       // You will also need cases for 'offer' and 'ice_candidate'
//       }
//     });
//   }
//
//   Future<void> makeCall(String targetId, RTCPeerConnection pc) async {
//     // Create an offer and send it via WebSocket
//     RTCSessionDescription offer = await pc.createOffer();
//     await pc.setLocalDescription(offer);
//
//     _channel?.sink.add(jsonEncode({
//       "type": "offer",
//       "target_id": targetId,
//       "sdp": offer.sdp,
//     }));
//   }
//
//   void dispose() {
//     _channel?.sink.close();
//   }
// }