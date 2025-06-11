#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>
#include <ArduinoJson.h>

#define MQ2_PIN 34
#define MQ4_PIN 35
#define MQ135_PIN 32
#define DHT_PIN 27
#define KY026_PIN 33
#define BUZZER_PIN 26

#define DHTTYPE DHT11
DHT dht(DHT_PIN, DHTTYPE);

const char* ssid = "SUA_REDE_WIFI";
const char* password = "SUA_SENHA_WIFI";

// Endpoint da API
const char* apiEndpoint = "https://biofi-api.onrender.com/api/sensores";
const char* token = ""; 



void setup() {
  Serial.begin(115200);
  
  pinMode(MQ2_PIN, INPUT);
  pinMode(MQ4_PIN, INPUT);
  pinMode(MQ135_PIN, INPUT);
  pinMode(KY026_PIN, INPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  dht.begin();

  WiFi.begin(ssid, password);
  Serial.print("Conectando ao WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi conectado!");
}

void loop() {
  float temperatura = dht.readTemperature();
  float umidade = dht.readHumidity();

  int gas_mq2 = analogRead(MQ2_PIN);
  int gas_mq4 = analogRead(MQ4_PIN);
  int gas_mq135 = analogRead(MQ135_PIN);
  bool chama = (digitalRead(KY026_PIN) == LOW); // LOW indica chama detectada

  // Limiar de segurança
  bool risco = (gas_mq2 > 400 || gas_mq4 > 400 || gas_mq135 > 400 || chama);

  if (risco) {
    digitalWrite(BUZZER_PIN, HIGH);
  } else {
    digitalWrite(BUZZER_PIN, LOW);
  }

  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(apiEndpoint);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Authorization", "Bearer " + String(token));

    StaticJsonDocument<256> body;
    body["temperatura"] = temperatura;
    body["umidade"] = umidade;
    body["mq2"] = gas_mq2;
    body["mq4"] = gas_mq4;
    body["mq135"] = gas_mq135;
    body["chama"] = chama;
    body["alerta"] = risco;

    String json;
    serializeJson(body, json);

    int response = http.POST(json);

    Serial.println("Payload enviado:");
    Serial.println(json);
    Serial.print("Código de resposta: ");
    Serial.println(response);

    http.end();
  }

  delay(10000);
}
