import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';

import '../../domain/repositories/auth_repository.dart';

final dioProvider = Provider((ref) => Dio());

final authRemoteDataSourceProvider = Provider(
  (ref) => AuthRemoteDataSource(ref.read(dioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider)),
);
