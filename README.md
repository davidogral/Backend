# Running the sample

## Running with the Dart SDK

You can run the example with the [Dart SDK](https://dart.dev/get-dart)
like this:

```
$ dart run bin/server.dart
Server listening on port 8080
```

And then from a second terminal:
```
$ curl http://0.0.0.0:8080
```

## 📝 Como Salvar e Sair no Nano

Sempre que for editar arquivos no Linux usando o `nano`, siga este passo a passo:

### ✅ Salvar Arquivo:
- Pressione: `CTRL + O`  
   (O "O" de "Output", para salvar o arquivo).

### ✅ Sair do Nano:
- Pressione: `CTRL + X`  
  (Para fechar o editor e voltar ao terminal).

## 🚀 Como ativar, iniciar e monitorar o serviço do servidor Dart no Linux

### ✅ Ativar e iniciar o serviço:

```bash
sudo systemctl daemon-servidor-dart
sudo systemctl enable servidor-dart
sudo systemctl start servidor-dart
```

### ✅ Ver status do serviço:

```bash
sudo systemctl status servidor-dart
```

Deve aparecer:  
`● gasense.service - ...`  
`Active: active (running) ✅`

### ✅ Ver log em tempo real:

```bash
journalctl -u servidor-dart -f
```

Esse comando mostra o **log em tempo real** do serviço.

**Dica:**  
Sempre que alterar o arquivo de serviço (`.service`), rode:  
```bash
sudo systemctl daemon-reload
sudo systemctl restart servidor-dart
```

Assim o sistema recarrega as configurações atualizadas.

**⚠️ Importante:**  
- `enable` → adiciona para iniciar automaticamente no boot.  
- `start` → inicia agora.  
- `status` → verifica se está rodando.  
- `journalctl` → acompanha os logs.
