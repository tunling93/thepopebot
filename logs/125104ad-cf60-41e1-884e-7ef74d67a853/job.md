Optimera thepopebot för kostnadseffektivitet genom att byta från Sonnet till Haiku som standardmodell.

Uppgifter:
1. Event Handler - Sätt EVENT_HANDLER_MODEL=claude-haiku-4 för Telegram chat
2. Docker Agent - Sätt repository variable MODEL=claude-haiku-4 för jobb  
3. Smart eskalering - Lägg till instruktioner för när Sonnet behövs (komplex kodning, stora refaktoreringar)
4. Dokumentation - Uppdatera README med kostnadspolicy och hur man växlar modeller
5. Verifiering - Testa att både chat och jobb fungerar med Haiku

Förväntad kostnadsminskning: 80-85% 🎯