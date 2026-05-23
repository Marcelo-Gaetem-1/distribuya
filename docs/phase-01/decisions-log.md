# Phase 1 — Block B: Modeling Decisions Log

## Customer domain

### Account

| Decisión | Resultado |
|---|---|
| Standard vs Custom | Standard (Account) |
| Person Account | No (es B2B puro) |
| Account Hierarchy nativa (ParentId) | Sí, para casos multi-sucursal |
| Record Types | 3: `Single_Customer`, `Parent_Customer`, `Branch_Customer` |

Justificación de los 3 Record Types: el padre y la sucursal tienen comportamientos muy distintos (el padre tiene límite de crédito y exposure, no recibe pedidos; la sucursal recibe pedidos pero no maneja crédito). Modelarlos con el mismo RT obligaría a lógica condicional en todos lados.

### Contact

| Decisión | Resultado |
|---|---|
| Standard vs Custom | Standard (Contact) |
| Relación con Account | Account Contact Relationships (many-to-many nativo) |

Justificación de Account Contact Relationships: refleja la realidad del cliente multi-sucursal (una persona puede trabajar en varias sucursales del mismo padre). Es feature standard que Salesforce provee, descarta tanto el modelo simple (no refleja realidad) como el Custom Object (viola regla 80/20).

### Customer credit data

| Decisión | Resultado |
|---|---|
| Campos en Account | `Credit_Limit__c`, `Credit_Used__c` (calculado), `Payment_Terms__c` (picklist), `Customer_Status__c` (picklist), `Segment__c` (picklist), `Onboarding_Stage__c` (picklist) |
| Historial de cambios crediticios | Custom Object `Credit_History__c` con timestamp y motivo de cada cambio |

Justificación del historial: el background en banca permite mostrar auditoría y trazabilidad (refuerza pilar **Trusted** del WAF). Patrón intermedio entre solo-campos (demasiado simple) y Custom Object completo (excesivo para distribuidor mayorista).

---

## Product domain

### Product

| Decisión | Resultado |
|---|---|
| Standard vs Custom | Standard (Product2) |

### Variantes

| Decisión | Resultado |
|---|---|
| Objeto vendible | `Product2` standard (sin cambios) |
| Agrupación de variantes | Custom Object `Product_Family__c` |
| Relación entre Family y Product2 | Master-Detail (la family es el padre, las variantes son hijas) |
| Pricing | En cada `Product2` (por variante), no en la family |
| Atributos en Family | Marca, imagen, descripción larga, manager de producto, etc. |

Justificación del patrón Family + Variants: Salesforce no tiene variantes nativas en Product2. La opción "padre Product2 + variantes en Custom Object" reimplementa Pricebook/Order/OrderItem y viola la regla 80/20. La opción "campo picklist agrupador" no soporta atributos propios ni crecimiento dinámico del catálogo. El patrón elegido respeta a Product2 como entidad vendible y modela la noción de "family" donde único pertenece.

### Categories

| Decisión | Resultado |
|---|---|
| Modelo | Custom Object `Product_Category__c` |
| Atributos iniciales | `Name`, `Display_Order__c`, `Icon_URL__c`, `Active__c`, `Description__c` (Manager opcional) |
| Relación con `Product_Family__c` | Lookup (no Master-Detail — la family puede existir sin categoría asignada) |

Decisión justificada aplicando el framework picklist vs Custom Object (ver [docs/patterns/picklist-vs-custom-object.md](../patterns/picklist-vs-custom-object.md)).

### Pricebook base

| Decisión | Resultado |
|---|---|
| Objeto de listas de precios | `Pricebook2` standard |
| `PricebookEntry` | Standard (conecta Product2 con precio) |

### Advanced pricing (closed)

Three interconnected sub-decisions covering pricing strategy.

*Sub-decision 1 — Pricebook structure*

| Decision | Result |
|---|---|
| Pricebook strategy | 3 × `Pricebook2` (one per segment): "Retailer", "Restaurant", "Small Business" |
| Order-to-Pricebook assignment | `Order.Pricebook2Id` set based on `Account.Segment__c` |
| Default for new customers without segment yet | "Small Business" Pricebook |

Rationale: native standard pattern for segment-based pricing, auditable for catalog teams, no custom logic required. Reinforces *Trusted* and *Composable* pillars of WAF.

*Sub-decision 2 — Customer-level price override*

| Decision | Result |
|---|---|
| Override model | Custom Object `Customer_Price__c` |
| Initial fields | `Account__c` (lookup), `Product2__c` (lookup), `Override_Price__c` (currency), `Effective_Date__c`, `End_Date__c`, `Negotiated_By__c` (User lookup), `Notes__c` |
| Application logic | Apex `PricingService` (Phase 2): checks active customer override first, falls back to segment Pricebook entry |
| v2 roadmap | Migration path to Salesforce Revenue Cloud Advanced documented in README |

Rationale: validated against picklist-vs-CustomObject framework (4 of 5 questions favor Custom Object). Pricebook-per-customer alternative does not scale; Salesforce CPQ is in End-of-Sale phase as of 2024-2025, so not future-proof for v2 — Revenue Cloud Advanced is the strategic successor.

*Sub-decision 3 — Volume-based pricing tiers*

| Decision | Result |
|---|---|
| Tier model | Custom Object `Price_Tier__c` |
| Initial fields | Link to `PricebookEntry__c` (or `Product2__c`, TBD in fine modeling), `Min_Quantity__c`, `Max_Quantity__c` (nullable for last tier), `Tier_Price__c`, `Effective_Date__c`, `End_Date__c` |
| Application logic | `PricingService` cascade order: customer override → applicable tier by quantity → base Pricebook entry |
| Unified model option | Possible future evolution to single `Price_Tier__c` with optional `Account__c` field, replacing `Customer_Price__c`. Deferred (YAGNI). |

Rationale: hardcoded tier fields on `PricebookEntry` do not scale beyond a fixed number of tiers; unified model with `Customer_Price__c` was evaluated but deferred to avoid premature complexity.

---

## Pending in Block B (next sessions)

- **Pricing avanzado** (próxima sesión): cuántos pricebooks usar (uno único vs uno por segmento), modelo de override de precio por cliente, modelo de descuentos por volumen (Price Tiers como Custom Object).
- **Order domain**: Order standard sí/no, OrderItem, lifecycle de estados (Pendiente / En revisión / Aprobado / En picking / Enviado / Entregado / Pagado / Cancelado), trazabilidad.
- **Approval matrix modeling**: cómo se materializan los 3 niveles de aprobación (Approval Process standard vs Flow custom).
- **Stock reservation modeling**: Custom Object `Stock_Reservation__c` con timeout, integración con disponibilidad.
- **Sharing model**: OWD por objeto, role hierarchy, sharing rules, permission sets.
- **ADRs formales** (Block B Sesión 3): se priorizan los 9 candidatos y se escriben 5-7 ADRs reales.
- **ERD final**: diagrama Mermaid C2/C3 con todo el modelo.

## Pending in Block D (materialization)

- Generación de metadata XML en `force-app/main/default/objects/...` (acá entra Claude Code en serio).
- sfdx-project.json configurado.
- Push a la org Salesforce Developer Edition.
- Primer commit con la org realmente configurada.
