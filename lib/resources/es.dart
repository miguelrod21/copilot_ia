class AppPhrases {
  // Errors
  static const String noListeningAvailable = 'Reconocimiento de voz no disponible en este dispositivo.';
  static const String noLocaleSelected = 'No se puede iniciar escucha activa. Verifica el idioma.';
  static const String missingApiKey = 'Error: OPENAI_API_KEY no encontrada en .env';
  static const String errorInitializingVoice = 'Error inicializando reconocimiento de voz: ';
  // Logging
  static const String passiveStart = '[Conversia] INICIO escucha pasiva';
  static const String activeStart = '[Conversia] INICIO escucha principal';

  static const String passiveResult = '[Conversia] Escucha pasiva resultado: ';
  static const String activeResult = '[Conversia] Escucha principal resultado: ';
  
  static const String passiveEnd = '[Conversia] FIN escucha pasiva';
  static const String activeEnd = '[Conversia] FIN escucha principal (vuelve a pasiva)';
  
  static const String passiveKeywordDetected = '[Conversia] Palabra clave detectada: "hola"';
  static const String voiceAlreadyListening = '[Conversia] Ya está escuchando pasivamente o activamente, o no hay idioma seleccionado.';
  
  // UI
  static const String appTitle = 'Conversia';
  static const String deniedPermission = 'Permiso de micrófono denegado. Habilítalo en ajustes.';
  static const String defaultPrompt = 'Pulsa o di "Oye chat" y habla';
  static const String buttonListening = 'Escuchando';
  static const String buttonListen = 'Escuchar';

  //ChatGPT
  static const String defaultChatResponse = 'Respuesta IA: ';
  static const String errorChatGPTConnection = 'Error al conectar con ChatGPT. Verifica tu conexión a Internet y la clave API.';
  static const String KeyWordPassiveListening = 'Oye chat';
}