import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';

class UsbController {
  UsbController() {
    UsbSerial.usbEventStream?.listen((event) {
      if (event.event == UsbEvent.ACTION_USB_ATTACHED) connect();
      if (event.event == UsbEvent.ACTION_USB_DETACHED) disconnect();
    });
  }

  ValueNotifier<bool> isConnected = ValueNotifier(false);

  static const _ch340VendorId = 0x1A86;
  static const _ch340ProductId = 0x7523;
  static const _baudRate = 9600;

  UsbDevice? _device;
  UsbPort? _port;

  Future<void> connect() async {
    var usbDeviceList = await UsbSerial.listDevices();

    try {
      _device = usbDeviceList.firstWhere((device) => _isCH340(device));
    } catch (e) {
      _device = null;
    }

    if (_device != null) {
      _port = await _device!.create();
      if (_port != null && await _port!.open()) {
       await _port!.setDTR(true);
       await _port!.setRTS(true);
       await _port!.setPortParameters(_baudRate, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
       isConnected.value = true;
      }
    }
  }

  void disconnect() async {
    await _port?.close();
    _port = null;
    _device = null;
    isConnected.value = false;
  }

  void toggleConnection() {
    if (_port != null && _device != null) {
      disconnect();
    } else {
      connect();
    }
  }

  void sendCommand(String command) async {
    if (command.length > 0) {
      try {
        await _port?.write(Uint8List.fromList(utf8.encode(command)));
      } catch (e) {
        disconnect();
      }
    }
  }

  bool _isCH340(UsbDevice device) => device.vid == _ch340VendorId && device.pid == _ch340ProductId;
}
