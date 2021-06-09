import 'dart:io';

import 'package:multicast_dns/multicast_dns.dart';

MDnsClient getClient() {
  MDnsClient c = MDnsClient(rawDatagramSocketFactory: (dynamic host, int port,
      {bool reuseAddress = true, bool? reusePort, int ttl = 255}) {
    /* Windows sets ReusePort to false, otherwise we get  
    * Dart Socket ERROR: ../../third_party/dart/runtime/bin/socket_win.cc:194: `reusePort` not supported for Windows
    */
    bool rp = (Platform.isWindows) ? false : reusePort ?? false;
    return RawDatagramSocket.bind(host, port,
        reuseAddress: reuseAddress, reusePort: rp, ttl: ttl);
  });
  return c;
}

Future<void> startMdns(String service) async {
  MDnsClient _mdns = getClient();
  // InternetAddress? ia =
  //     Platform.isWindows ? InternetAddress("224.0.0.251") : null;
  await _mdns.start();
  // Get the PTR record for the service.
  await for (final PtrResourceRecord ptr in _mdns
      .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(service))) {
    await for (final SrvResourceRecord srv in _mdns.lookup<SrvResourceRecord>(
        ResourceRecordQuery.service(ptr.domainName))) {
      final String bundleId = ptr.domainName;
      print(
          'Dart observatory instance found at ${srv.target}:${srv.port} for "$bundleId".');
      await for (final IPAddressResourceRecord ipA
          in _mdns.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target))) {}
      await for (final IPAddressResourceRecord ipA
          in _mdns.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv6(srv.target))) {}
    }
    await for (final TxtResourceRecord txtA in _mdns
        .lookup<TxtResourceRecord>(ResourceRecordQuery.text(ptr.domainName))) {
      print(txtA.text);
    }
  }
}
