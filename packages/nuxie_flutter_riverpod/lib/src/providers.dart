import 'package:nuxie_flutter/nuxie_flutter.dart';
import 'package:riverpod/riverpod.dart';

final nuxieProvider = Provider<Nuxie>((_) => Nuxie.instance);
