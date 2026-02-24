import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:doctor_booking_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:doctor_booking_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:doctor_booking_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:doctor_booking_app/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:doctor_booking_app/features/doctor/data/datasources/doctor_remote_data_source.dart';
import 'package:doctor_booking_app/features/doctor/data/repositories/doctor_repository_impl.dart';
import 'package:doctor_booking_app/features/doctor/domain/repositories/doctor_repository.dart';
import 'package:doctor_booking_app/features/doctor/presentation/bloc/doctor_bloc.dart';

import 'package:doctor_booking_app/features/booking/data/datasources/booking_remote_data_source.dart';
import 'package:doctor_booking_app/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:doctor_booking_app/features/booking/domain/repositories/booking_repository.dart';
import 'package:doctor_booking_app/features/booking/presentation/bloc/booking_bloc.dart';

import 'package:doctor_booking_app/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:doctor_booking_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:doctor_booking_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:doctor_booking_app/features/chat/presentation/bloc/chat_bloc.dart';

import 'package:doctor_booking_app/features/call/data/datasources/call_remote_data_source.dart';
import 'package:doctor_booking_app/features/call/presentation/bloc/call_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features

  // Auth
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl(), firestore: sl()),
  );

  // Doctor
  sl.registerFactory(() => DoctorBloc(repository: sl()));
  sl.registerLazySingleton<DoctorRepository>(
    () => DoctorRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<DoctorRemoteDataSource>(
    () => DoctorRemoteDataSourceImpl(firestore: sl()),
  );

  // Booking
  sl.registerFactory(() => BookingBloc(repository: sl()));
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(firestore: sl()),
  );

  // Chat
  sl.registerFactory(() => ChatBloc(repository: sl()));
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(firestore: sl()),
  );

  // Call
  sl.registerFactory(() => CallBloc(remoteDataSource: sl()));
  sl.registerLazySingleton(() => CallRemoteDataSource());

  // External
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseMessaging.instance);
}
