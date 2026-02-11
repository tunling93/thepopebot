Optimera thepopebot för kostnadseffektivitet genom att implementera Ollama för heartbeats och sätta Haiku som standard modell.

**Uppgifter:**
1. **Installera Ollama-support** - Uppdatera Dockerfile för att inkludera Ollama
2. **Konfigurera heartbeat** - Ändra CRONS.json från agent-typ till command-typ som använder lokal Ollama för hälsokontroller
3. **Sätt Haiku som default** - Uppdatera EVENT_HANDLER_MODEL till claude-haiku-4 för chat
4. **Repository-inställningar** - Dokumentera hur man sätter MODEL variabeln till claude-haiku-4
5. **Växlingslogik** - Skapa instruktioner för när/hur man använder Sonnet för komplexa uppgifter
6. **Dokumentation** - Uppdatera SECURITY.md eller skapa COST_OPTIMIZATION.md med alla förändringar

Fokus på att spara pengar genom att använda gratis lokal LLM för rutinuppgifter medan Anthropic API sparas för riktigt arbete.