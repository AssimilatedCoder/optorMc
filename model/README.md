# Model Service: Ollama

This service runs Ollama (https://ollama.com/) in a container for local LLM inference.

- Exposes API on port 11434
- Downloads open-source code model as required (e.g., StarCoder, CodeLlama, GLM, etc.)

## Usage

Upon `docker-compose up`, service will be available internally as `ollama:11434` and externally as `localhost:11434`.

See https://ollama.com/library for available models and API usage.
