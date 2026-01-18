class BuildingDetection {
  static String getBuildingName(double lat, double lon) {
    // CALIBRATED: Boys Hostel 3 & 4 Area (South Cluster)
    // Shifted North-East to catch your laptop's current drift
    if (lat <= 13.5570 && lat >= 13.5540 && lon >= 80.0265 && lon <= 80.0285) {
      return "Boys Hostel 4";
    }

    // CALIBRATED: Academic Block
    // Narrowed and shifted to avoid overlap with drifted Hostel coordinates
    if (lat <= 13.5560 && lat >= 13.5535 && lon >= 80.0250 && lon <= 80.0264) {
      return "Acad Block";
    }

    // Widened Boys Hostel 1 & 2 Area (North Cluster)
    if (lat <= 13.5590 && lat >= 13.5571 && lon >= 80.0240 && lon <= 80.0270) {
      return "Boys Hostel Cluster (North)";
    }

    // Widened Girls Hostel Area
    if (lat <= 13.5640 && lat >= 13.5610 && lon >= 80.0200 && lon <= 80.0230) {
      return "Girls Hostel";
    }

    return "Campus Grounds";
  }
}