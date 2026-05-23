# Project Charter

## 1.1 Contexto

Proyecto flagship de portafolio para avanzar hacia rol de Salesforce Architect en 2-3 años. Background: Functional Tech Lead en GFT, experiencia en banca, certificado en Data Cloud y Agentforce. Proyecto ficticio (no usa datos ni código de cliente real) pero realista a nivel arquitectura.

## 1.2 Dominio

**"DistribuYa"** — plataforma SaaS para un distribuidor mayorista B2B que vende a retailers, restaurantes y comercios pequeños. Cubre:

- Catálogo con precios por cliente
- Pedidos online
- Aprobaciones por límite de crédito
- Integración con ERP / logística / pagos
- Portal self-service
- Forecasting de demanda

**Perfil operacional decidido**: 500-2000 pedidos/día, stock mixto (mayoría holgado, algunos SKUs ajustados).

## 1.3 Stack técnico

- Salesforce Developer Edition / Trailhead Playground
- Experience Cloud, Apex, LWC, Flow, Platform Events
- Data Cloud + Agentforce (Fase 5)
- Lucid para diagramas C1 (hero)
- Mermaid para diagramas C2/C3 (versionados en repo)
- GitHub público
- VS Code + Cursor + Claude Code
- Salesforce CLI (sfdx)

## 1.4 Fases del proyecto

| Fase | Foco | Duración estimada |
|---|---|---|
| **1** | Fundación y modelo de datos | 2 semanas |
| **2** | Automatización core (Flow + Apex + Platform Events) | 3 semanas |
| **3** | Experience Cloud + LWC (portal B2B) | 3 semanas |
| **4** | Integraciones (ERP, logística, pagos) | 3 semanas |
| **5** | AI Layer (Data Cloud + Model Builder + Agentforce) | 4 semanas |
| **Subchat 00** | Arquitectura y ADRs (transversal) | continuo |

## 1.5 Estilo de trabajo (cómo opera el mentor)

- Trato como futuro Architect, no como junior.
- Mentor-guided: el mentor hace preguntas antes de dar soluciones. El aprendiz trabaja los problemas; el mentor orienta.
- Para código: no modificaciones directas. Se muestran diffs paso a paso con justificación.
- Para decisiones: trade-offs y opciones, no respuestas. El aprendiz decide.
- Honestidad técnica: si el mentor no está seguro, lo dice. No inventa.
- Pacing sostenible: ~90 min/día.
- Resúmenes técnicos concisos y claros.
- Idioma de conversación: español. Idioma de artefactos del repo: inglés.

## 1.6 No-goals

- No es réplica de trabajo de cliente real.
- No se busca terminar rápido — se busca aprender y mostrar profundidad.
- Una fase a la vez, no en paralelo.
