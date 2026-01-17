class BuildingDetection {
  static String getBuildingName(double lat, double lon) {
    // Academic Block
    if (lat <= 13.555636 && lat >= 13.554988 && lon >= 80.026425 && lon <= 80.027112) {
      return "Acad Block";
    }
    // Boys Hostel 4
    if (lat <= 13.552917 && lat >= 13.552521 && lon >= 80.025705 && lon <= 80.026258) {
      return "Boys Hostel 4";
    }
    // Boys Hostel 3
    if (lat <= 13.553634 && lat >= 13.553265 && lon >= 80.025667 && lon <= 80.026225) {
      return "Boys Hostel 3";
    }
    // Mess B
    if (lat <= 13.553183 && lat >= 13.553015 && lon >= 80.025931 && lon <= 80.026219) {
      return "Mess B";
    }
    // Boys Hostel 2
    if (lat <= 13.556764 && lat >= 13.556530 && lon >= 80.024756 && lon <= 80.025195) {
      return "Boys Hostel 2";
    }
    // Boys Hostel 1
    if (lat <= 13.557274 && lat >= 13.557189 && lon >= 80.024797 && lon <= 80.025387) {
      return "Boys Hostel 1";
    }
    // Mess A
    if (lat <= 13.557060 && lat >= 13.556872 && lon >= 80.024812 && lon <= 80.025128) {
      return "Mess A";
    }
    // Girls Hostel (NEW)
    if (lat <= 13.562047 && lat >= 13.561212 && lon >= 80.021310 && lon <= 80.022104) {
      return "Girls Hostel";
    }

    return "Campus Grounds";
  }
}