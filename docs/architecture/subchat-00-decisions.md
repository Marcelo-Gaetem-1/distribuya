# Architecture Decisions — Subchat 00

El subchat 00 funciona como **Tribunal**: cuando una fase llega a una decisión arquitectónica gorda y transversal, se "sube" allí, se discuten trade-offs, se decide, se genera ADR formal, y se vuelve a la fase a implementar.

## 2.1 Las 9 decisiones cerradas

| # | Decisión | Resultado | En una frase: por qué |
|---|---|---|---|
| 1 | Herramienta de diagramas | Híbrido: Lucid (C1 hero) + Mermaid (C2/C3 en repo) | Pulido para el hero, versionable para el detalle |
| 2 | Función del subchat 00 | Tribunal | Entrena el músculo de justificar antes de cerrar |
| 3 | Estructura en repo | `/docs/adr/0001-titulo-en-kebab-case.md` | Convención adoptada por la industria |
| 4 | Criterio para abrir ADR | Rework significativo si se revierte | Evita ahogarse en documentación |
| 5 | Idioma de artefactos | Inglés | Objetivo: rol internacional |
| 6 | Hero angle del portafolio | Well-Architected Framework | Lenguaje oficial de Architect en Salesforce |
| 7 | Formato de ADR | MADR + sección WAF Alignment | Estándar de industria + alineación con hero |
| 8 | Niveles de C4 a mantener | C1 obligatorio (Lucid) + C2 obligatorio (Mermaid) + C3 selectivo solo para Salesforce Core e Integración + C4 no usar | Pragmático, sin sobre-documentar |
| 9 | Status workflow del ADR | Estándar (Proposed → Accepted → Superseded → Deprecated). Sin Rejected | Las opciones descartadas viven dentro del ADR aceptado en "Considered Options" |

## 2.2 Conceptos fundamentales del subchat 00

**ADR (Architecture Decision Record)**: documento Markdown corto que captura *una* decisión arquitectónica y *por qué* se tomó. Vive en `/docs/architecture/adr/`. No se edita: si la decisión cambia, se crea otro ADR que la reemplaza (status `Superseded`).

**C4 Model**: forma de diagramar arquitectura en 4 niveles de zoom:
- **C1 Context**: el sistema rodeado de actores externos.
- **C2 Container**: bloques principales dentro del sistema.
- **C3 Component**: componentes dentro de un container.
- **C4 Code**: clases / archivos dentro de un componente (no se usa en Salesforce, lo cubren Schema Builder y la jerarquía de Apex).

**Well-Architected Framework (WAF)**: marco oficial de Salesforce para evaluar diseños. 5 pilares:
- **Trusted** — seguro, auditable, cumple regulaciones.
- **Easy to Change** — se modifica sin romper cosas.
- **Adaptable** — escala y se ajusta a nuevos requisitos.
- **Resilient** — tolera fallos.
- **Composable** — sus piezas se reutilizan.

**Tribunal**: rol del subchat 00. Decisiones gordas se proponen, se discuten con trade-offs explícitos, se decide, se materializa en ADR.

## 2.3 Plantilla de ADR (MADR + WAF)

```markdown
# ADR XXXX: <Decision title>

## Status
Proposed | Accepted | Superseded by ADR-YYYY | Deprecated

## Context and Problem Statement
<Situation, forces in play, the problem.>

## Decision Drivers
- <Driver 1>
- <Driver 2>

## Considered Options
1. <Option A>
2. <Option B>
3. <Option C>

## Decision Outcome
Chosen: **<Option X>**, because <one-sentence justification>.

## Pros and Cons of the Options

### Option A
- ✅ Pro 1
- ❌ Con 1

### Option B
- ✅ Pro 1
- ❌ Con 1

## Consequences
- <What changes operationally>
- <Trade-offs accepted>
- <Impact on platform limits, packaging, sharing>

## Alignment with Well-Architected Framework

| Pillar | Impact | Notes |
|---|---|---|
| Trusted | Positive / Negative / Neutral | <Why> |
| Easy to Change | Positive / Negative / Neutral | <Why> |
| Adaptable | Positive / Negative / Neutral | <Why> |
| Resilient | Positive / Negative / Neutral | <Why> |
| Composable | Positive / Negative / Neutral | <Why> |
```
