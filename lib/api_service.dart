import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // TODO: set your server base URL
  static const base = 'https://aqua-hummingbird-953655.hostingersite.com/';
  static const int Version = 42500;
  static const String CVersionNo = "4.25";
  static int newVersion = 0;
  static String newVersionNo = "";
  static String feature = "";
  static String url = "";

  static Future<void> isLatestVersion() async {
    final prefs = await SharedPreferences.getInstance();
    // Load previous saved values (in case server fails)
    newVersion = prefs.getInt('newVersion') ?? 0;
    url = prefs.getString('url') ?? "";
    newVersionNo = prefs.getString('newVersionNo') ?? "";
    feature = prefs.getString('feature') ?? "";

    try {
      final res = await http.get(Uri.parse('$base/AppDetails.php'));

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);

        // Update variables
        newVersion = int.parse(data['Version']);
        url = data['url'];
        newVersionNo = data['VersionNum'];
        feature = data['Feature'];

        // Save to local storage
        await prefs.setInt('newVersion', newVersion);
        await prefs.setString('url', url);
        await prefs.setString('newVersionNo', newVersionNo);
        await prefs.setString('feature', feature);
      }
    } catch (e) {
      // No internet OR server error → using local stored values
      print("Error fetching latest version. Loaded local cached data.");
    }
  }

  static Future<void> urlOpen() async {
    final Uri _url = Uri.parse(url);
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }

  // --- vehicletype ---
  static Future<List<dynamic>> getVehicleTypes() async {
    try {
      final res = await http.get(Uri.parse('$base/get_vehicle_types.php'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body); // expects list of {TypeID, Type, Image}
      }
    } catch (e) {
      return await DBHelper.getAllTypes();
    }
    throw Exception('Failed to fetch types');
  }

  // --- vehicles (create or upsert) ---
  static Future<bool> pushVehicle(Map<String, dynamic> v) async {
    final body = v.map((k, val) => MapEntry(k, val?.toString() ?? ''));
    final res = await http.post(
      Uri.parse('$base/insert_vehicle.php'),
      body: body,
    );
    final data = jsonDecode(res.body);
    return data['success'] == true;
  }

  // --- travels (create) ---
  static Future<bool> pushTravel(Map<String, dynamic> t) async {
    final body = t.map((k, val) => MapEntry(k, val?.toString() ?? ''));
    final res = await http.post(
      Uri.parse('$base/insert_travel.php'),
      body: body,
    );
    final data = jsonDecode(res.body);
    return data['success'] == true;
  }

  static Future<List<dynamic>> fetchUserVehicles(String uid) async {
    final res = await http.get(
      Uri.parse('$base/get_user_vehicles.php?uid=$uid'),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  static Future<List<dynamic>> fetchUserTravels(String uid) async {
    final res = await http.get(
      Uri.parse('$base/get_user_travels.php?uid=$uid'),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  static Future<String> saveTypeImage(String saveName) async {
    final basediv = await getApplicationDocumentsDirectory();
    final dir = Directory("${basediv.path}/TypeImage");

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final file = File("${dir.path}/$saveName");

    // condition you asked for:
    if (file.existsSync()) {
      print("Image already exists, skipping download");
      return "TypeImage/$saveName";
    }
    final response = await http.get(Uri.parse('$base/TypesImage/$saveName'));
    await file.writeAsBytes(response.bodyBytes);

    print("Downloaded new image: $saveName");
    return "TypeImage/$saveName";
  }

  static Future<File> getTypeFile(String relativePath) async {
    final base = await getApplicationDocumentsDirectory();
    return File("${base.path}/$relativePath");
  }
}
