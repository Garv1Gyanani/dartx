import 'package:dartx/dartx.dart';

class UserController {
  Future<Response> index(Context ctx) async {
    return ctx.json({'message': 'Index of User'});
  }
}
