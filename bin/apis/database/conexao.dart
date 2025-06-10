import 'package:postgres/postgres.dart';

PostgreSQLConnection? _conexaoPostgreSQL;

Future<PostgreSQLConnection> getConexao() async {
  if (_conexaoPostgreSQL == null) {
    _conexaoPostgreSQL = PostgreSQLConnection(
      "localhost",
      5432,
      "gasense",
      username: "postgres",
      password: "postgres",
    );
    await _conexaoPostgreSQL?.open();
  }
  return _conexaoPostgreSQL!;
}
