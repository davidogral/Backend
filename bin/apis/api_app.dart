import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import "database/conexao.dart";
import "../service/senha_hash.dart";

Future<Response> gravarUsuarios(Request request) async {
  String corpoRequisicao = await request.readAsString();
  Map<String, dynamic> dados = jsonDecode(corpoRequisicao);

  try {
    // Gera hash da senha se existir
    if (dados.containsKey('senha') && dados['senha'] != null) {
      dados['senha_hash'] = gerarHashSenha(dados['senha']);
      dados.remove('senha');
    }

    PostgreSQLConnection _conexaoPostgreSQL = await getConexao();
    await _conexaoPostgreSQL.transaction((ctx) async {
      if (dados['id_usuario'] != null && dados['id_usuario'] > 0) {
        // Atualização
        await ctx.query('''
          UPDATE usuarios 
          SET nome = @nome, email = @email, senha_hash = @senha_hash, data_cadastro = @data_cadastro 
          WHERE id_usuario = @id_usuario
          ''', substitutionValues: dados);
      } else {
        // Inserção
        PostgreSQLResult result = await ctx.query('''
          INSERT INTO usuarios (nome, email, senha_hash, data_cadastro) 
          VALUES (@nome, @email, @senha_hash, @data_cadastro) 
          RETURNING id_usuario
          ''', substitutionValues: dados);
        dados['id_usuario'] = result.first[0];
      }
    });
    return Response.ok(jsonEncode({'id': dados['id']}));
  } catch (erro) {
    return Response.internalServerError(body: 'ERRO: $erro');
  }
}

Future<Response> pesquisarUsuarios(Request request) async {
  String corpo = await request.readAsString();
  Map<String, dynamic> dados = jsonDecode(corpo);

  String email = dados['email'];
  String senha = dados['senha'];

  try {
    PostgreSQLConnection conn = await getConexao();
    List<List<dynamic>> resultado = await conn.query(
      '''
      SELECT id_usuario, nome, email, senha_hash, data_cadastro 
      FROM usuarios 
      WHERE email = @email
      ''',
      substitutionValues: {'email': email},
    );

    if (resultado.isEmpty) {
      return Response.forbidden(jsonEncode({'erro': 'Usuário não encontrado'}));
    }

    var usuario = resultado.first;
    String senhaHashArmazenada = usuario[3];

    if (!validarSenha(senha, senhaHashArmazenada)) {
      return Response.forbidden(jsonEncode({'erro': 'Senha incorreta'}));
    }

    return Response.ok(
      jsonEncode({
        'id_usuario': usuario[0],
        'nome': usuario[1],
        'email': usuario[2],
        'data_cadastro': usuario[4],
      }),
    );
  } catch (erro) {
    return Response.internalServerError(body: 'ERRO: $erro');
  }
}

Future<Response> deletarUsuario(Request request) async {
  String corpo = await request.readAsString();
  Map<String, dynamic> dados = jsonDecode(corpo);

  int idUsuario = dados['id_usuario'];

  try {
    PostgreSQLConnection conn = await getConexao();
    await conn.query(
      '''
      DELETE FROM usuarios WHERE id_usuario = @id_usuario
      ''',
      substitutionValues: {'id_usuario': idUsuario},
    );

    return Response.ok(jsonEncode({'status': 'usuário deletado com sucesso'}));
  } catch (erro) {
    return Response.internalServerError(body: 'ERRO: $erro');
  }
}

Future<Response> buscarLeiturasRecentes(Request request) async {
  try {
    PostgreSQLConnection conn = await getConexao();

    var params = request.url.queryParameters;
    String? idDispositivo = params['id_dispositivo'];
    int limite = int.tryParse(params['limite'] ?? '') ?? 10;

    String sql = '''
      SELECT id_dispositivo, data_hora, temperatura, umidade, fogo, gas_glp, compostos_toxicos, gas_metano
      FROM leituras
    ''';

    Map<String, dynamic> substitutionValues = {'limite': limite};

    if (idDispositivo != null) {
      sql += ' WHERE id_dispositivo = @id_dispositivo';
      substitutionValues['id_dispositivo'] = idDispositivo;
    }

    sql += ' ORDER BY data_hora DESC LIMIT @limite';

    List<List<dynamic>> resultado = await conn.query(
      sql,
      substitutionValues: substitutionValues,
    );

    List<Map<String, dynamic>> leituras = resultado.map((linha) {
      return {
        'id_dispositivo': linha[0],
        'data_hora': (linha[1] as DateTime).toIso8601String(),
        'temperatura': linha[2],
        'umidade': linha[3],
        'fogo': linha[4],
        'gas_glp': linha[5],
        'compostos_toxicos': linha[6],
        'gas_metano': linha[7],
      };
    }).toList();

    return Response.ok(jsonEncode(leituras));
  } catch (erro) {
    return Response.internalServerError(body: 'ERRO: $erro');
  }
}

Future<Response> buscarAlertasAtivos(Request request) async {
  try {
    PostgreSQLConnection conn = await getConexao();

    var params = request.url.queryParameters;
    String? idDispositivo = params['id_dispositivo'];

    String sql = '''
      SELECT id_alerta, id_dispositivo, tipo_alerta, valor_medido, data_hora, nivel_criticidade, resolvido
      FROM alertas
      WHERE resolvido = false
    ''';

    Map<String, dynamic> substitutionValues = {};

    if (idDispositivo != null) {
      sql += ' AND id_dispositivo = @id_dispositivo';
      substitutionValues['id_dispositivo'] = idDispositivo;
    }

    sql += ' ORDER BY data_hora DESC';

    List<List<dynamic>> resultado = await conn.query(
      sql,
      substitutionValues: substitutionValues,
    );

    List<Map<String, dynamic>> alertas = resultado.map((linha) {
      return {
        'id_alerta': linha[0],
        'id_dispositivo': linha[1],
        'tipo_alerta': linha[2],
        'valor_medido': linha[3],
        'data_hora': (linha[4] as DateTime).toIso8601String(),
        'nivel_criticidade': linha[5],
        'resolvido': linha[6],
      };
    }).toList();

    return Response.ok(jsonEncode(alertas));
  } catch (erro) {
    return Response.internalServerError(body: 'ERRO: $erro');
  }
}


Future<Response> buscarDispositivoPorId(Request request) async {
  try {
    PostgreSQLConnection conn = await getConexao();

    var params = request.url.queryParameters;
    String? idDispositivo = params['id_dispositivo'];

    if (idDispositivo == null || idDispositivo.isEmpty) {
      return Response.badRequest(body: 'Parâmetro id_dispositivo é obrigatório');
    }

    String sql = '''
      SELECT d.id_dispositivo, d.nome, d.localizacao, d.data_cadastro, d.id_usuario, l.latitude, l.longitude
      FROM dispositivos d
      LEFT JOIN localizacoes l ON d.id_localizacao = l.id_localizacao
      WHERE d.id_dispositivo = @id_dispositivo
      LIMIT 1
    ''';

    List<List<dynamic>> resultado = await conn.query(
      sql,
      substitutionValues: {'id_dispositivo': idDispositivo},
    );

    if (resultado.isEmpty) {
      return Response.notFound('Dispositivo não encontrado');
    }

    var linha = resultado.first;
    Map<String, dynamic> dispositivo = {
      'id_dispositivo': linha[0],
      'nome': linha[1],
      'localizacao': linha[2],
      'data_cadastro': (linha[3] as DateTime).toIso8601String(),
      'id_usuario': linha[4],
      'latitude': linha[5],
      'longitude': linha[6],
    };

    return Response.ok(jsonEncode(dispositivo));
  } catch (erro) {
    return Response.internalServerError(body: 'ERRO: $erro');
  }
}
