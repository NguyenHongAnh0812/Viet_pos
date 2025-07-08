class AppPaymentSetting {
  final String bankCode;
  final String bankAccount;
  final String bankName;
  final String accountName;

  AppPaymentSetting({
    required this.bankCode,
    required this.bankAccount,
    required this.bankName,
    required this.accountName,
  });

  factory AppPaymentSetting.fromFirestore(Map<String, dynamic> data) {
    return AppPaymentSetting(
      bankCode: data['bank_code'] ?? '',
      bankAccount: data['bank_account'] ?? '',
      bankName: data['bank_name'] ?? '',
      accountName: data['account_name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bank_code': bankCode,
      'bank_account': bankAccount,
      'bank_name': bankName,
      'account_name': accountName,
    };
  }
} 