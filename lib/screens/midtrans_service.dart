import 'dart:convert';
import 'package:http/http.dart' as http;

class MidtransService {
  final String serverKey = 'YOUR_SERVER_KEY';

  Future<String> createTransaction(int amount, String orderId, String name, String email, String phone) async {
    final url = 'https://app.midtrans.com/snap/v1/transactions';
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Basic ' + base64Encode(utf8.encode(serverKey)),
    };
    final body = json.encode({
      "payment_type": "bank_transfer",
      "transaction_details": {
        "order_id": orderId,
        "gross_amount": amount,
      },
      "bank_transfer": {
        "bank": "bca"
      },
      "customer_details": {
        "first_name": name,
        "email": email,
        "phone": phone,
      }
    });

    final response = await http.post(Uri.parse(url), headers: headers, body: body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['redirect_url'];
    } else {
      throw Exception('Failed to create transaction');
    }
  }
}
