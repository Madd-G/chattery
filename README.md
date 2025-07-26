# Chattery 💬

Chattery is an intelligent chat application built with Flutter and powered by a local Large Language Model (LLM) through Ollama. It features real-time streaming responses from the LLM and dynamic conversation summarization.

-----

## Features ✨

  * **Real-time LLM Chat**: Engage in conversations with a local LLM (e.g., Llama2), receiving responses as they're generated.
  * **Conversation Summarization**: Automatically generates a concise summary of your ongoing chat, helping you keep track of key discussion points.
  * **Context-aware Conversations**: The LLM uses previous conversation history and the generated summary to provide more relevant and coherent responses.
  * **Text-to-Speech (Optional)**: (Currently commented out, but ready to be enabled\!) The app can speak out the LLM's responses.
  * **Clean Architecture**: Built with Riverpod for robust state management and a well-structured folder architecture for maintainability and scalability.

-----

## Architecture & Project Structure 🏗️

This project follows a clean, modular architecture to ensure maintainability, scalability, and separation of concerns.

```
chattery_app/
├── lib/
│   ├── main.dart                               # Application entry point
│   ├── core/                                   # Core components reusable across the app
│   │   ├── models/
│   │   │   └── message.dart                    # Data model for chat messages
│   │   ├── constants/
│   │   │   └── api_constants.dart              # API constants (e.g., Ollama URL, model name)
│   │   └── services/
│   │       └── tts_service.dart                # Abstraction and implementation for Text-to-Speech
│   ├── features/                               # Contains independent feature modules
│   │   └── chat/                               # The chat feature module
│   │       ├── presentation/                   # UI Layer (Widgets)
│   │       │   ├── widgets/
│   │       │   │   ├── chat_bubble.dart        # Individual chat message bubble widget
│   │       │   │   └── message_input.dart      # Input field and send button widget
│   │       │   └── chat_page.dart              # Main UI screen for the chat feature
│   │       ├── data/
│   │       │   └── chat_repository.dart        # Data Layer: Handles API calls to Ollama
│   │       └── application/                    # Application Layer (Business Logic & State Management)
│   │           ├── providers/
│   │           │   ├── chat_providers.dart     # Riverpod providers related to chat state
│   │           │   └── summary_providers.dart  # Riverpod providers related to summary state
│   │           └── notifiers/
│   │               ├── chat_notifier.dart      # StateNotifier for managing chat messages and logic
│   │               └── summary_notifier.dart   # StateNotifier for managing conversation summary
└── pubspec.yaml
└── README.md
```

-----

## Demo Video 🎥

Watch a demo of Chattery in action:


https://github.com/user-attachments/assets/20c54270-0bcd-4e30-8835-7d1d8c38e3bb


Display table



https://github.com/user-attachments/assets/e40dd302-ae6a-4a5b-b318-aeaf7e2ab280




-----

## Contributing 🤝

Contributions are welcome\! Please feel, free to open issues or submit pull requests.

-----

## Acknowledgements 🙏

  * [Flutter](https://flutter.dev/) - For providing a fantastic framework for cross-platform development.
  * [Riverpod](https://riverpod.dev/) - For a robust and safe state management solution.
  * [Ollama](https://ollama.ai/) - For making local LLMs accessible and easy to use.
  * [flutter\_tts](https://pub.dev/packages/flutter_tts) - For Text-to-Speech functionality.
  * [http](https://pub.dev/packages/http) - For making HTTP requests.

-----
