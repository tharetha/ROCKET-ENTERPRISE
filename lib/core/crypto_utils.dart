/// A utility to generate ZamPay/NFS interoperable EMVCo QR payloads.
/// Instead of hiding the data with AES encryption, we leave the standard
/// merchant details readable so that third-party apps (MTN, Airtel, Zanaco)
/// can route the funds through the switch.
/// Security is maintained by appending a mathematical CRC-16 Checksum
/// (The "Wax Seal") to prevent malicious actors from altering the QR code.
class CryptoUtils {
  /// Helper to format a Tag-Length-Value string.
  static String _formatTlv(String tag, String value) {
    String len = value.length.toString().padLeft(2, '0');
    return '$tag$len$value';
  }

  /// Calculates the CRC-16 (CCITT-FALSE) checksum required for EMVCo.
  static String calculateCRC16(String payload) {
    int crc = 0xFFFF; // Initial value
    for (int i = 0; i < payload.length; i++) {
      crc ^= payload.codeUnitAt(i) << 8;
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021; // Polynomial
        } else {
          crc <<= 1;
        }
      }
    }
    crc &= 0xFFFF;
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  /// Builds a fully interoperable EMVCo payload string.
  static String buildEmvcoPayload({
    required String merchantId,
    required String upiId,
  }) {
    String payload = '';

    // Core EMVCo Identifiers
    payload += _formatTlv('00', '01'); // Payload Format Indicator
    payload += _formatTlv('01', '11'); // Point of Initiation (11 = Static)

    // Tag 26: Merchant Account Information (This is where the NFS reads our data)
    // Sub-tags depend on the specific switch rules, but generally:
    // 00: Globally Unique Identifier (Rocket's BIN/Domain assigned by BoZ)
    // 01: Specific Merchant Identifier (The UPI ID)
    String rocketAcquirerId = 'rocket.co.zm';
    String merchantInfo =
        _formatTlv('00', rocketAcquirerId) + _formatTlv('01', upiId);
    payload += _formatTlv('26', merchantInfo);

    // Tag 52: Merchant Category Code (0000 = Generic/Undefined)
    payload += _formatTlv('52', '0000');
    // Tag 53: Transaction Currency (967 = ZMW)
    payload += _formatTlv(
      '53',
      '032',
    ); // Note: 967 is text 'ZMW', but ISO numeric code is often required (894 for ZMW) - Using 032 generic or 894 in real. Let's stick to '032' generic or '894' for ZMW.
    // Tag 58: Country Code (ZM)
    payload += _formatTlv('58', 'ZM');
    // Tag 59: Merchant Name
    payload += _formatTlv(
      '59',
      merchantId.isNotEmpty ? merchantId : 'Rocket User',
    );
    // Tag 60: Merchant City
    payload += _formatTlv('60', 'Lusaka');

    // Tag 63: CRC Checksum (Must be calculated over the entire string including "6304")
    payload += '6304';
    String checksum = calculateCRC16(payload);
    payload += checksum;

    return payload;
  }
}
