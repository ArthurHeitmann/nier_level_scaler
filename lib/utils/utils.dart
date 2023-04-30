
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crclib/catalog.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:tuple/tuple.dart';

import '../fileTypeUtils/utils/ByteDataWrapper.dart';

const double titleBarHeight = 25;

final _crc32 = Crc32();
int crc32(String str) {
  return _crc32.convert(utf8.encode(str)).toBigInt().toInt();
}

bool isInt(String str) {
  return int.tryParse(str) != null;
}

bool isDouble(String str) {
  return double.tryParse(str) != null;
}

Future<List<String>> getDatFiles(String extractedDir) async {
  var pakInfo = join(extractedDir, "dat_info.json");
  if (await File(pakInfo).exists()) {
    var datInfoJson = jsonDecode(await File(pakInfo).readAsString());
    return datInfoJson["files"].cast<String>();
  }
  var fileOrderMetadata = join(extractedDir, "file_order.metadata");
  if (await File(fileOrderMetadata).exists()) {
    var filesBytes = await ByteDataWrapper.fromFile(fileOrderMetadata);
    var numFiles = filesBytes.readUint32();
    var nameLength = filesBytes.readUint32();
    List<String> datFiles = List
      .generate(numFiles, (i) => filesBytes.readString(nameLength)
        .split("\u0000")[0]);
    return datFiles;
  }

  return await (Directory(extractedDir).list())
    .where((file) => file is File && extension(file.path).length <= 3)
    .map((file) => file.path)
    .toList();
}


Future<List<String>> getDatFileList(String datDir) async {
  var datInfoPath = join(datDir, "dat_info.json");
  if (await File(datInfoPath).exists())
    return _getDatFileListFromJson(datInfoPath);
  var metadataPath = join(datDir, "file_order.metadata");
  if (await File(metadataPath).exists())
    return _getDatFileListFromMetadata(metadataPath);
  
  throw Exception("No dat_info.json or file_order.metadata found in $datDir");
}

Future<List<String>> _getDatFileListFromJson(String datInfoPath) async {
  var datInfoJson = jsonDecode(await File(datInfoPath).readAsString());
  List<String> files = [];
  var dir = dirname(datInfoPath);
  for (var file in datInfoJson["files"]) {
    files.add(join(dir, file));
  }
  files = files.toSet().toList();
  files.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  return files;
}

Future<List<String>> _getDatFileListFromMetadata(String metadataPath) async {
  var metadataBytes = await ByteDataWrapper.fromFile(metadataPath);
  var numFiles = metadataBytes.readUint32();
  var nameLength = metadataBytes.readUint32();
  List<String> files = [];
  for (var i = 0; i < numFiles; i++)
    files.add(metadataBytes.readString(nameLength).replaceAll("\x00", ""));
  files = files.toSet().toList();
  files.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  var dir = dirname(metadataPath);
  files = files.map((file) => join(dir, file)).toList();

  return files;
}


void Function() throttle(void Function() func, int waitMs, { bool leading = true, bool trailing = false }) {
  Timer? timeout;
  int previous = 0;
  void later() {
		previous = leading == false ? 0 : DateTime.now().millisecondsSinceEpoch;
		timeout = null;
		func();
	}
	return () {
		var now = DateTime.now().millisecondsSinceEpoch;
		if (previous != 0 && leading == false)
      previous = now;
		var remaining = waitMs - (now - previous);
		if (remaining <= 0 || remaining > waitMs) {
			if (timeout != null) {
				timeout!.cancel();
				timeout = null;
			}
			previous = now;
			func();
		}
    else if (timeout != null && trailing) {
			timeout = Timer(Duration(milliseconds: remaining), later);
		}
	};
}

void Function() debounce(void Function() func, int waitMs, { bool leading = false }) {
  Timer? timeout;
  return () {
		timeout?.cancel();
		timeout = Timer(Duration(milliseconds: waitMs), () {
			timeout = null;
			if (!leading)
        func();
		});
		if (leading && timeout != null)
      func();
	};
}

Key? makeReferenceKey(Key? key) {
  if (key is GlobalKey || key is UniqueKey)
    return ValueKey(key);
  return key;
}

bool between(num val, num min, num max) => val >= min && val <= max;

T clamp<T extends num> (T value, T minVal, T maxVal) {
  return max(min(value, maxVal), minVal);
}

Future<void> waitForNextFrame() {
  var completer = Completer<void>();
  SchedulerBinding.instance.addPostFrameCallback((_) => completer.complete());
  return completer.future;
}

/*
TS example:
export function floorTo(number: number, precision: number): number {
	return Math.floor(number * Math.pow(10, precision)) / Math.pow(10, precision);
}

function _numberToShort(num: number): { n: number, s?: string } {
	switch (Math.abs(num).toString().length) {
		case 0:
		case 1:
		case 2:
		case 3:
			return { n: num };
		case 4:
			return { n: floorTo(num / 1000, 2), s: "k"};
		case 5:
		case 6:
			return { n: floorTo(num / 1000, 0), s: "k"};
		case 7:
			return { n: floorTo(num / 1000000, 2), s: "m"};
		case 8:
		case 9:
			return { n: floorTo(num / 1000000, 0), s: "m"};
		case 10:
			return { n: floorTo(num / 1000000000, 2), s: "b"};
		case 11:
		case 12:
			return { n: floorTo(num / 1000000000, 0), s: "b"};
		case 13:
			return { n: floorTo(num / 1000000000000, 2), s: "t"};
		case 14:
		case 15:
			return { n: floorTo(num / 1000000000000, 0), s: "t"};
		default:
			return { n: 0, s: " - ∞" }
	}
}

/** convert long numbers like 11,234 to 11k */
export function numberToShort(num: number): string {
	return Object.values(_numberToShort(num)).join("");
}
 */
double _floorTo(double number, int precision) {
  return (number * pow(10, precision)).floor() / pow(10, precision);
}
Tuple3<num, int, String> _formatNum(num number) {
  switch (number.abs().floor().toString().length) {
    case 0:
    case 1:
    case 2:
    case 3:
      return Tuple3(number, 0, "");
    case 4:
      return Tuple3(_floorTo(number / 1000, 2), 2, "k");
    case 5:
    case 6:
      return Tuple3(_floorTo(number / 1000, 1), 1, "k");
    case 7:
      return Tuple3(_floorTo(number / 1000000, 2), 2, "m");
    case 8:
    case 9:
      return Tuple3(_floorTo(number / 1000000, 1), 1, "m");
    case 10:
      return Tuple3(_floorTo(number / 1000000000, 2), 2, "b");
    case 11:
    case 12:
      return Tuple3(_floorTo(number / 1000000000, 1), 1, "b");
    case 13:
      return Tuple3(_floorTo(number / 1000000000000, 2), 2, "t");
    case 14:
    case 15:
      return Tuple3(_floorTo(number / 1000000000000, 1), 1, "t");
    default:
      return const Tuple3(0, 0, " - ∞");
  }
}
/// Shortens large numbers to a more readable format
String numberToShort(num number) {
  var result = _formatNum(number);
  var isInt = number.toDouble() == number.floorToDouble();
  if (isInt)
    return "${result.item1.toInt()} ${result.item3}";
  return "${result.item1.toStringAsFixed(result.item2)} ${result.item3}";
}

Future<List<T>> waitBatched<T>(Iterable<Future<T>> futures, int batchSize) async {
  List<T> results = [];
  while (futures.isNotEmpty) {
    var batch = futures.take(batchSize);
    futures = futures.skip(batchSize);
    results.addAll(await Future.wait(batch));
  }
  return results;
}

Future<void> backupFile(String file) async {
  var backupName = "$file.backup";
  if (!await File(backupName).exists() && await File(file).exists())
    await File(file).copy(backupName);
}

extension NumberExtension on num {
  String toStringUpTo(int decimals) {
    var str = toStringAsFixed(decimals);
    str = str.replaceAll(RegExp(r"\.?0+$"), "");
    return str;
  }
}
