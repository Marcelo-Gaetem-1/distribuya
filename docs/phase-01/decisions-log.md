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

#### Order domain

Eight sub-decisions covering order management, approvals, and stock reservation. The richest functional area of Phase 1, touching most discovery decisions.

**Order header** (closed)

| Decision | Result |
|---|---|
| Standard vs Custom | Standard (`Order`) |
| Salesforce Order Management | Not activated (OMS is retail/B2C-oriented, doesn't fit B2B wholesale) |
| Record Types in Order | None — instead, picklist `Order_Type__c` with values `Standard` / `Sample` / `Return` / `Internal` |

Rationale: `Order` semantics match perfectly; OMS adds licensing and complexity without proportional value for B2B wholesale; order subtypes are homogeneous enough not to warrant RTs.

**OrderItem** (closed)

| Decision | Result |
|---|---|
| Standard vs Custom | Standard (`OrderItem`) |
| Relation to product variants | Native (`OrderItem.Product2Id` points to variant Product2) |
| Applied price traceability | Custom fields: `Applied_Price_Source__c` (picklist: `Base_Price` / `Customer_Override` / `Volume_Tier`), `Price_Modifier_Id__c` (text, references `Customer_Price__c` or `Price_Tier__c`), `Base_Price__c` (currency), `Discount_Amount__c` (currency, calculated) |
| Record Types | None |

Rationale: Standard `OrderItem` covers the data model; custom traceability fields enable audit trail and reporting that reinforces *Trusted* pillar of WAF — critical for B2B disputes and credit decisions.

**Lifecycle states** (closed)

| Decision | Result |
|---|---|
| State model | Multi-dimensional — three orthogonal status fields |
| `Status` (standard) | Untouched; preserves native Order behavior (Draft / Activated) |
| `Credit_Status__c` (picklist) | `Not_Required` / `Pending` / `Approved` / `Rejected` |
| `Fulfillment_Status__c` (picklist) | `Not_Started` / `In_Picking` / `Shipped` / `Delivered` / `Cancelled` |
| `Payment_Status__c` (picklist) | `Not_Paid` / `Partially_Paid` / `Paid` |
| `Order_Stage__c` (formula) | Derived from the three status fields; user-friendly representation for UI |

Rationale: order lifecycle in B2B is genuinely multi-dimensional (an order can be `Delivered` and `Not_Paid` simultaneously under Net 30 terms). Linear status models force false sequentiality. Orthogonal fields enable cleaner reporting (e.g., "all delivered unpaid orders") and natural ownership separation by domain (credit team, fulfillment, finance). Reinforces *Composable* pillar of WAF.

**Approval orchestration** (closed)

| Decision | Result |
|---|---|
| Mechanism | **Flow Orchestration** (standard Flow type as of Spring '26, no licensing barrier) |
| Stages | Pre-Approval Analysis (auto) → Approval Decision (interactive) → Apply Decision (auto) |
| Exposure and tier calculation | Background Step invokes Flow that reads `Credit_Approval_Tier__mdt` |
| Dynamic approver assignment | Orchestration variable set in background step, used as assignee in interactive step |
| Audit trail | Orchestration Run history (native) |
| Order state during flow | `Credit_Status__c` updated by background steps as stages progress |

Rationale: Flow Orchestration is designed specifically for multi-step, multi-user processes — exactly the credit approval pattern. Salesforce Spring '26 made it a standard Flow type with no usage caps, removing the previous licensing barrier. Approval Process classic was considered but rejected: its native dynamic assignment is limited, and Orchestration provides richer audit and modern tooling. The choice signals architectural awareness of post-2026 platform capabilities.

**Approval matrix configuration** (closed)

| Decision | Result |
|---|---|
| Storage of approval tiers | Custom Metadata Type `Credit_Approval_Tier__mdt` |
| Initial tiers | Tier 1: 0-100% (Sales Rep); Tier 2: 100-150% (Manager); Tier 3: 150%+ (Credit Team) |
| Tier attributes | `Min_Ratio__c`, `Max_Ratio__c` (nullable for top tier), `Approver_Role__c` |

Rationale: Custom Metadata is the appropriate Salesforce primitive for business configuration that changes infrequently, is admin-maintainable, and needs to be versioned with metadata (not data). Hardcoding in Apex or Flow would block admin changes; Custom Object would mix configuration with transactional data.

**Stock model** (closed)

| Decision | Result |
|---|---|
| Source of truth for physical stock | ERP (external system) |
| Salesforce stock representation | `Product2.Available_Stock__c` (number, populated by periodic sync from ERP) |
| Sync metadata fields | `Product2.Stock_Last_Sync__c` (datetime) |
| Cross-reference identifiers | `Product2.ERP_Product_ID__c` (text, external ID, unique) |
| Reservation layer | Salesforce-only (independent of ERP), custom object `Stock_Reservation__c` |
| Available for new orders | Computed at runtime: `Available_Stock__c - SUM(active reservations)` |
| Order confirmation to ERP | Outbound integration in Phase 4 (post-approval, post-payment as applicable) |

Rationale: hybrid model with clear ownership — ERP owns physical stock, Salesforce owns commercial transactions and temporary reservations. Avoids ERP latency on every reservation check while maintaining a single source of truth for physical inventory. Reinforces *Resilient* (Salesforce works during ERP outages for new orders) and *Composable* (clear domain boundaries) pillars of WAF.

**Stock reservation model** (closed)

| Decision | Result |
|---|---|
| Object | Custom Object `Stock_Reservation__c` |
| Granularity | One reservation per `OrderItem` |
| Relation to `OrderItem` | **Lookup** (not Master-Detail) — preserves audit trail if `OrderItem` is deleted |
| Status workflow | `Active` → terminal states `Consumed` / `Released` / `Expired` |
| Atributes | `Product2__c` (lookup), `OrderItem__c` (lookup), `Quantity__c`, `Status__c`, `Expiry_Timestamp__c`, `Reservation_Reason__c`, `Released_By__c`, `Released_Reason__c` |
| Available stock calculation | Deferred to Phase 2 (Apex Service Layer): runtime aggregate vs maintained rollup decision |

Rationale: Lookup over Master-Detail because reservations must outlive their `OrderItem` for auditability — consistent with `Credit_History__c` pattern. Status workflow with terminal states enables reporting on approval delays (`Expired` count), rejection rates (`Released` count), and conversion (`Consumed` count). Orphan handling on `OrderItem` deletion is solved by a simple Record-Triggered Flow.

**Reservation timeout** (closed)

| Decision | Result |
|---|---|
| Mechanism | **Time-Triggered Path** in Record-Triggered Flow on `Stock_Reservation__c` |
| Trigger | After Create — each reservation schedules its own expiration |
| Offset basis | Field `Expiry_Timestamp__c` |
| Action when timestamp reached | Verify `Status__c = 'Active'`; if true, set `Status__c = 'Expired'` |
| Enterprise safety net | Scheduled Apex as a sweep backup — deferred (YAGNI) but architecturally noted |

Rationale: Time-Triggered Paths provide near-exact expiration timing (minute-level granularity) and per-record scheduling, which is cleaner conceptually than a centralized scheduled job sweeping records. The choice signals familiarity with modern Flow capabilities (Scheduled Paths, Summer '21+). Centralized scheduled Apex was considered but rejected as primary mechanism due to coarser granularity (typically 15-minute resolution).

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
