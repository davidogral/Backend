// Função para gravar leituras
import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import "database/conexao.dart";

const double limiteTemperatura = 50.0;
const double limiteUmidade = 90.0;
const double limiteGasGlp = 300.0;
const double limiteToxicos = 200.0;
const double limiteMetano = 400.0;

Future<Response> gravarLeituras(Request request) async {
  String corpo = await request.readAsString();
  Map<String, dynamic> dados = jsonDecode(corpo);

  String? chave = request.headers['Authorization'];
  if (chave == null || chave.isEmpty) {
    return Response.forbidden(
      jsonEncode({'erro': 'Chave de autorização ausente'}),
    );
  }

  try {
    PostgreSQLConnection conn = await getConexao();

    List<List<dynamic>> resultado = await conn.query(
      'SELECT "id_dispositivo" FROM "dispositivos" WHERE "chave" = @chave',
      substitutionValues: {'chave': chave},
    );
    if (resultado.isEmpty) {
      return Response.forbidden(jsonEncode({'erro': 'Chave inválida'}));
    }

    String idDispositivo = resultado.first[0];
    dados['id_dispositivo'] = idDispositivo;

    await conn.transaction((ctx) async {
      await ctx.query('''
        INSERT INTO leituras (
          id_dispositivo, data_hora, temperatura, umidade, fogo,
          gas_glp, compostos_toxicos, gas_metano
        ) VALUES (
          @id_dispositivo, @data_hora, @temperatura, @umidade, @fogo,
          @gas_glp, @compostos_toxicos, @gas_metano
        )
        ''', substitutionValues: dados);

      // Valida se deve criar alerta
      await verificarEGravarAlerta(ctx, dados);
    });

    return Response.ok(jsonEncode({'status': 'ok'}));
  } catch (erro) {
    return Response.internalServerError(body: 'ERRO: $erro');
  }
}

Future<void> verificarEGravarAlerta(
  PostgreSQLExecutionContext ctx,
  Map dados,
) async {
  List<Map<String, dynamic>> alertas = [];

  void adicionarAlerta(String tipo, dynamic valor) {
    alertas.add({
      'id_dispositivo': dados['id_dispositivo'],
      'tipo_alerta': tipo,
      'valor_medido': valor,
      'data_hora': dados['data_hora'],
      'nivel_criticidade': 'ALTA', // ou baseado no valor
      'resolvido': false,
    });
  }

  if (dados['temperatura'] > limiteTemperatura) {
    adicionarAlerta('Temperatura', dados['temperatura']);
  }
  if (dados['umidade'] > limiteUmidade) {
    adicionarAlerta('Umidade', dados['umidade']);
  }
  if (dados['gas_glp'] > limiteGasGlp) {
    adicionarAlerta('GLP', dados['gas_glp']);
  }
  if (dados['compostos_toxicos'] > limiteToxicos) {
    adicionarAlerta('Compostos Tóxicos', dados['compostos_toxicos']);
  }
  if (dados['gas_metano'] > limiteMetano) {
    adicionarAlerta('Metano', dados['gas_metano']);
  }
  if (dados['fogo'] == true || dados['fogo'] == 1) {
    adicionarAlerta('Fogo', 1);
  }

  for (var alerta in alertas) {
    await ctx.query('''
      INSERT INTO alertas (
        id_dispositivo, tipo_alerta, valor_medido, data_hora, nivel_criticidade, resolvido
      ) VALUES (
        @id_dispositivo, @tipo_alerta, @valor_medido, @data_hora, @nivel_criticidade, @resolvido
      )
      ''', substitutionValues: alerta);
    print("funfo");
  }
}

// Função para gravar alertas
Future<Response> gravarAlertas(Request request) async {
  String corpo = await request.readAsString();
  Map<String, dynamic> dados = jsonDecode(corpo);

  try {
    PostgreSQLConnection conn = await getConexao();
    await conn.transaction((ctx) async {
      if (dados['id_alerta'] != null && dados['id_alerta'] > 0) {
        await ctx.query('''
          UPDATE alertas SET
            id_dispositivo = @id_dispositivo,
            tipo_alerta = @tipo_alerta,
            valor_medido = @valor_medido,
            data_hora = @data_hora,
            nivel_criticidade = @nivel_criticidade,
            resolvido = @resolvido
          WHERE id_alerta = @id_alerta
          ''', substitutionValues: dados);
      } else {
        PostgreSQLResult result = await ctx.query('''
          INSERT INTO alertas (
            id_dispositivo, tipo_alerta, valor_medido,
            data_hora, nivel_criticidade, resolvido
          ) VALUES (
            @id_dispositivo, @tipo_alerta, @valor_medido,
            @data_hora, @nivel_criticidade, @resolvido
          ) RETURNING id_alerta
          ''', substitutionValues: dados);
        dados['id_alerta'] = result.first[0];
      }
    });
    return Response.ok(jsonEncode({'id_alerta': dados['id_alerta']}));
  } catch (erro) {
    return Response.internalServerError(body: 'ERRO: $erro');
  }
}
