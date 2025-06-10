import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'apis/database/conexao.dart';
import 'apis/api_disposivo.dart';
import 'apis/api_app.dart';

final _router = Router()
  ..get('/', _echoHandler)

  // Rotas para dispositivos
  ..post('/gravarLeituras', gravarLeituras)
  ..post('/gravarAlertas', gravarAlertas)

  // Rotas para usuários (app)
  ..post('/gravarUsuarios', gravarUsuarios)
  ..post('/pesquisarUsuarios', pesquisarUsuarios)
  ..post('/deletarUsuario', deletarUsuario)
  ..get('/leituras', buscarLeiturasRecentes) // Pode receber query params para filtrar dispositivo, período etc.
  ..get('/alertas', buscarAlertasAtivos) // Para buscar alertas, pode ser filtrado por dispositivo, estado, etc.
  ..post('/pesquisarDispositivos', buscarDispositivoPorId); // Pode receber filtros no body para buscar dispositivos com localização

Response _echoHandler(Request request) {
  print("Ouvimos");
  return Response.ok("200");
}

void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(_router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');

  // Testar a conxão com o banco de dados
  try {
    await getConexao();
    print('Conexão estabelecida com sucesso!');
  } catch (e) {
    print('Erro ao conectar ao banco de dados: $e');
  }
}
