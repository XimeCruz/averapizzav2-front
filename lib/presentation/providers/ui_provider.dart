import 'package:flutter/material.dart';

/// Provider para manejar el estado de la UI (sidebar, modales, etc.)
class UiProvider extends ChangeNotifier {
  bool _isSidebarExpanded = false;
  bool canShowSidebarText = false;
  
  bool get isSidebarExpanded => _isSidebarExpanded;
  
  void toggleSidebar() {
    _isSidebarExpanded = !_isSidebarExpanded;
    notifyListeners();
  }
  
  void setSidebarExpanded(bool value) {
    if (_isSidebarExpanded != value) {
      _isSidebarExpanded = value;
      notifyListeners();
    }
  }
  
  // Inicializar según el tamaño de pantalla
  void initializeSidebarState(double screenWidth) {
    if (screenWidth > 1400 && !_isSidebarExpanded) {
      _isSidebarExpanded = true;
      notifyListeners();
    }
  }
}