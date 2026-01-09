import 'package:bookbed/core/services/permission_service.dart';
import 'package:bookbed/core/services/platform_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'service_providers.g.dart';

@riverpod
PermissionService permissionService(PermissionServiceRef ref) {
  return PermissionService();
}

@riverpod
PlatformService platformService(PlatformServiceRef ref) {
  return PlatformService();
}
