# Standard vs Custom — Decision Framework

## Standard vs Custom — the 4 Legitimate Reasons to Go Custom

Regla general: **favorecer Standard siempre que el estándar tenga la semántica correcta**. Ir Custom solo si:

1. La **semántica del estándar no encaja** (ej: usar Opportunity para algo que no es una venta).
2. Los **campos custom no son suficientes** — necesitás estructura completamente distinta.
3. Los **límites o comportamientos** del estándar bloquean el caso de uso.
4. Hay un **patrón especializado** donde lo custom es la convención del dominio.

Si te apartás del estándar sin una de estas 4 razones, no es defendible en una entrevista de Architect.

## "Standard" is Not a Single Thing — It's a Spectrum

Antes de ir Custom, explorar:
- Feature básica out-of-the-box del objeto standard.
- Features standard avanzadas que requieren activación explícita (Account Contact Relationships, Multi-Currency, Person Accounts, Field Service, etc.).
- Custom solo cuando ninguno del espectro Standard sirve.
