import 'dart:convert';
import 'package:crypto/crypto.dart';

// Função para criar hash SHA-256 da senha
String gerarHashSenha(String senha) {
  final bytes = utf8.encode(senha); // transforma a senha em bytes
  final digest = sha256.convert(bytes); // calcula hash
  return digest.toString(); // retorna string hex do hash
}

bool validarSenha(String senhaDigitada, String hashArmazenado) {
  var bytes = utf8.encode(senhaDigitada);
  var hashCalculado = sha256.convert(bytes).toString();
  return hashCalculado == hashArmazenado;
}