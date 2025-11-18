import 'package:flutter/foundation.dart';
import '../../../../shared/models/daily_price_model.dart';

/// Local state cache for calendar prices with optimistic updates
class PriceCalendarState extends ChangeNotifier {
  // Cache of monthly prices: Map<Month, Map<Date, Price>>
  final Map<DateTime, Map<DateTime, DailyPriceModel>> _priceCache = {};
  
  // Undo/Redo stacks
  final List<PriceAction> _undoStack = [];
  final List<PriceAction> _redoStack = [];
  final int _maxHistorySize = 50;

  // Get prices for a specific month
  Map<DateTime, DailyPriceModel>? getMonthPrices(DateTime month) {
    final monthKey = DateTime(month.year, month.month);
    return _priceCache[monthKey];
  }

  // Set entire month data (from server)
  void setMonthPrices(DateTime month, Map<DateTime, DailyPriceModel> prices) {
    final monthKey = DateTime(month.year, month.month);
    _priceCache[monthKey] = Map.from(prices);
    notifyListeners();
  }

  // Optimistically update a single date
  void updateDateOptimistically(
    DateTime month,
    DateTime date,
    DailyPriceModel? newPrice,
    DailyPriceModel? oldPrice,
  ) {
    final monthKey = DateTime(month.year, month.month);
    final dateKey = DateTime(date.year, date.month, date.day);
    
    _priceCache[monthKey] ??= {};
    
    if (newPrice != null) {
      _priceCache[monthKey]![dateKey] = newPrice;
    } else {
      _priceCache[monthKey]!.remove(dateKey);
    }
    
    // Add to undo stack
    _addToUndoStack(PriceAction(
      type: PriceActionType.updateSingle,
      month: month,
      dates: [date],
      oldPrices: oldPrice != null ? {dateKey: oldPrice} : {},
      newPrices: newPrice != null ? {dateKey: newPrice} : {},
    ));
    
    notifyListeners();
  }

  // Optimistically update multiple dates
  void updateDatesOptimistically(
    DateTime month,
    List<DateTime> dates,
    Map<DateTime, DailyPriceModel> oldPrices,
    Map<DateTime, DailyPriceModel> newPrices,
  ) {
    final monthKey = DateTime(month.year, month.month);
    _priceCache[monthKey] ??= {};
    
    for (final date in dates) {
      final dateKey = DateTime(date.year, date.month, date.day);
      if (newPrices.containsKey(dateKey)) {
        _priceCache[monthKey]![dateKey] = newPrices[dateKey]!;
      }
    }
    
    // Add to undo stack
    _addToUndoStack(PriceAction(
      type: PriceActionType.updateBulk,
      month: month,
      dates: dates,
      oldPrices: oldPrices,
      newPrices: newPrices,
    ));
    
    notifyListeners();
  }

  // Rollback optimistic update on error
  void rollbackUpdate(DateTime month, Map<DateTime, DailyPriceModel> oldPrices) {
    final monthKey = DateTime(month.year, month.month);
    _priceCache[monthKey] ??= {};
    
    for (final entry in oldPrices.entries) {
      _priceCache[monthKey]![entry.key] = entry.value;
    }
    
    notifyListeners();
  }

  // Undo last action
  bool undo() {
    if (_undoStack.isEmpty) return false;
    
    final action = _undoStack.removeLast();
    _redoStack.add(action);
    
    // Trim redo stack if too large
    if (_redoStack.length > _maxHistorySize) {
      _redoStack.removeAt(0);
    }
    
    _applyReverse(action);
    notifyListeners();
    return true;
  }

  // Redo last undone action
  bool redo() {
    if (_redoStack.isEmpty) return false;
    
    final action = _redoStack.removeLast();
    _undoStack.add(action);
    
    _applyAction(action);
    notifyListeners();
    return true;
  }

  void _addToUndoStack(PriceAction action) {
    _undoStack.add(action);
    
    // Trim stack if too large
    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }
    
    // Clear redo stack when new action is performed
    _redoStack.clear();
  }

  void _applyAction(PriceAction action) {
    final monthKey = DateTime(action.month.year, action.month.month);
    _priceCache[monthKey] ??= {};
    
    for (final entry in action.newPrices.entries) {
      _priceCache[monthKey]![entry.key] = entry.value;
    }
  }

  void _applyReverse(PriceAction action) {
    final monthKey = DateTime(action.month.year, action.month.month);
    _priceCache[monthKey] ??= {};
    
    for (final entry in action.oldPrices.entries) {
      _priceCache[monthKey]![entry.key] = entry.value;
    }
    
    // Remove dates that didn't exist before
    for (final date in action.dates) {
      final dateKey = DateTime(date.year, date.month, date.day);
      if (!action.oldPrices.containsKey(dateKey)) {
        _priceCache[monthKey]!.remove(dateKey);
      }
    }
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  
  String? get lastActionDescription {
    if (_undoStack.isEmpty) return null;
    final action = _undoStack.last;
    return action.type == PriceActionType.updateSingle
        ? 'Ažuriranje 1 datuma'
        : 'Ažuriranje ${action.dates.length} datuma';
  }

  // Clear cache for a specific month (force refresh)
  void invalidateMonth(DateTime month) {
    final monthKey = DateTime(month.year, month.month);
    _priceCache.remove(monthKey);
    notifyListeners();
  }

  // Clear entire cache
  void clearCache() {
    _priceCache.clear();
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
}

/// Action types for undo/redo
enum PriceActionType {
  updateSingle,
  updateBulk,
}

/// Represents a price update action for undo/redo
class PriceAction {
  final PriceActionType type;
  final DateTime month;
  final List<DateTime> dates;
  final Map<DateTime, DailyPriceModel> oldPrices;
  final Map<DateTime, DailyPriceModel> newPrices;

  PriceAction({
    required this.type,
    required this.month,
    required this.dates,
    required this.oldPrices,
    required this.newPrices,
  });
}
