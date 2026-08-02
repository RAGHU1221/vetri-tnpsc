import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  String _lang = 'ta';
  String get lang => _lang;
  bool get isTamil => _lang == 'ta';

  void toggleLang() {
    _lang = _lang == 'ta' ? 'en' : 'ta';
    notifyListeners();
  }

  // Exam group: 'G4' (Group 4/VAO), 'G2A' (Group 2/2A), 'NMMS' (8th std scholarship)
  String _examGroup = 'G4';
  String get examGroup => _examGroup;
  static const _labelsTa = {'G4': 'குரூப் 4', 'G2A': 'குரூப் 2/2A', 'NMMS': 'NMMS (8th)'};
  static const _labelsEn = {'G4': 'Group 4', 'G2A': 'Group 2/2A', 'NMMS': 'NMMS (8th)'};
  String get examGroupLabelTa => _labelsTa[_examGroup] ?? _examGroup;
  String get examGroupLabelEn => _labelsEn[_examGroup] ?? _examGroup;

  void setExamGroup(String g) {
    if (g == _examGroup) return;
    _examGroup = g;
    notifyListeners();
  }
}
