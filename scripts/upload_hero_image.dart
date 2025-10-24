import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Migration script to download Unsplash hero image and upload to Supabase Storage
///
/// Usage:
///   dart run scripts/upload_hero_image.dart
///
/// This will:
/// 1. Download the hero image from Unsplash
/// 2. Upload it to Supabase Storage bucket 'hero-images'
/// 3. Print the public URL to use in HomePage
Future<void> main() async {
  print('🚀 Starting hero image migration...\n');

  // Initialize Supabase
  print('📦 Initializing Supabase...');
  await Supabase.initialize(
    url: Platform.environment['SUPABASE_URL'] ?? '',
    anonKey: Platform.environment['SUPABASE_ANON_KEY'] ?? '',
  );

  final supabase = Supabase.instance.client;
  print('✅ Supabase initialized\n');

  // Download image from Unsplash
  final unsplashUrl = 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=1600&q=80';
  print('⬇️  Downloading image from Unsplash...');
  print('   URL: $unsplashUrl');

  final response = await http.get(Uri.parse(unsplashUrl));

  if (response.statusCode != 200) {
    print('❌ Failed to download image: ${response.statusCode}');
    exit(1);
  }

  final imageBytes = response.bodyBytes;
  print('✅ Downloaded ${imageBytes.length} bytes\n');

  // Upload to Supabase Storage
  print('⬆️  Uploading to Supabase Storage...');
  final fileName = 'hero-rab-island-${DateTime.now().millisecondsSinceEpoch}.jpg';
  final bucket = 'hero-images';

  try {
    // Create bucket if it doesn't exist (admin only)
    print('   Creating bucket "$bucket" if needed...');
    try {
      await supabase.storage.createBucket(
        bucket,
        BucketOptions(
          public: true,
          fileSizeLimit: 5 * 1024 * 1024, // 5MB
        ),
      );
      print('✅ Bucket created');
    } catch (e) {
      print('   Bucket already exists or insufficient permissions');
    }

    // Upload file
    print('   Uploading file: $fileName');
    final uploadResponse = await supabase.storage
        .from(bucket)
        .uploadBinary(
          fileName,
          imageBytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            cacheControl: '31536000', // 1 year cache
          ),
        );

    print('✅ Upload successful\n');

    // Get public URL
    final publicUrl = supabase.storage
        .from(bucket)
        .getPublicUrl(fileName);

    print('🎉 SUCCESS! Hero image uploaded to Supabase\n');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Public URL:');
    print(publicUrl);
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    print('📝 Next step:');
    print('   Update home_screen.dart line 54:');
    print('   backgroundImage: \'$publicUrl\',\n');

  } catch (e, stackTrace) {
    print('❌ Upload failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
