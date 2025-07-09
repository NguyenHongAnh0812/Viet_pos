/// Utility class for mapping inventory status between database and UI
class InventoryStatusMapper {
  /// Map database status to display text
  static String getStatusDisplayText(String dbStatus) {
    switch (dbStatus) {
      case 'draft':
        return 'Phiếu tạm';
      case 'checked':
        return 'Đã kiểm kê';
      case 'updated':
        return 'Đã cập nhật tồn kho';
      default:
        return 'Phiếu tạm';
    }
  }

  /// Map display text to database status
  static String getStatusDBValue(String displayText) {
    switch (displayText) {
      case 'Phiếu tạm':
        return 'draft';
      case 'Đã kiểm kê':
        return 'checked';
      case 'Đã cập nhật tồn kho':
        return 'updated';
      default:
        return 'draft';
    }
  }

  /// Get badge variant for status
  static String getBadgeVariant(String dbStatus) {
    switch (dbStatus) {
      case 'updated':
        return 'secondary';
      case 'checked':
        return 'warning';
      default:
        return 'defaultVariant';
    }
  }

  /// Get color for status chip
  static int getStatusColor(String dbStatus) {
    switch (dbStatus) {
      case 'updated':
        return 0xFF16A34A; // Green
      case 'checked':
        return 0xFF2563eb; // Blue
      default:
        return 0xFF9CA3AF; // Gray
    }
  }
} 