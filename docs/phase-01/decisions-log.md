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
| Relación entre Family y Product2 | ~~Master-Detail~~ → **Lookup, required, Restrict delete** (la family es el padre, las variantes son hijas) — ver nota de materialización |
| Pricing | En cada `Product2` (por variante), no en la family |
| Atributos en Family | Marca, imagen, descripción larga, manager de producto, etc. |

Justificación del patrón Family + Variants: Salesforce no tiene variantes nativas en Product2. La opción "padre Product2 + variantes en Custom Object" reimplementa Pricebook/Order/OrderItem y viola la regla 80/20. La opción "campo picklist agrupador" no soporta atributos propios ni crecimiento dinámico del catálogo. El patrón elegido respeta a Product2 como entidad vendible y modela la noción de "family" donde único pertenece.

> **Materialization finding (2026-05-30, Block D)**: the relationship was originally documented as **Master-Detail with Product2 as the detail (child)**. This is **not buildable on the platform**: a standard object (Product2) cannot be on the detail side of a master-detail relationship — only the master side. ([Salesforce Help — Tips and Considerations for Relationships](https://help.salesforce.com/s/articleView?id=sf.relationships_considerations.htm&type=5)). **Resolution**: `Product2.Product_Family__c` is a **Lookup** that is **required** with **Restrict delete** (a family cannot be deleted while it has variants). This preserves the "a variant must belong to a family" intent and referential integrity, while *avoiding* cascade-delete (which we do not want — products carry order history) and without needing roll-up summaries (not required in Phase 1). Any future need for roll-ups on the family is handled via Apex/Flow, not master-detail.

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

#### Sharing model

Six interconnected sub-decisions covering record visibility, role hierarchy, sharing rules, external (portal) users, and permission strategy. The sharing model is layered on top of all previously decided objects.

**Internal roles inventory** (closed)

Nine core roles for DistribuYa's commercial operation:

| Role | Responsibility | Main touchpoints |
|---|---|---|
| Sales Rep | Owns assigned Accounts; creates Orders | Account (owner), Order, Customer_Price__c (read) |
| Sales Manager | Supervises Sales Reps; Tier 2 credit approvals | Approval matrix Tier 2 |
| Sales Director | Top commercial role; full visibility | Reporting global |
| Credit Analyst | Reviews Tier 3 credit approvals | Credit_History__c (R/W) |
| Credit Manager | Supervises Credit Analysts; escalations | Credit_History__c, escalations |
| Operations / Fulfillment | Manages Fulfillment_Status lifecycle | Order, Stock_Reservation__c |
| Catalog Admin | Maintains catalog and pricing | Product2, Pricebooks, Customer_Price__c |
| Finance | Handles Payment_Status and invoicing | Order |
| System Admin | Full access; user/config management | All |

Customer Service, Marketing, and Read-Only Reporting deferred as optional extensions (can be added without restructuring).

**Organization-Wide Defaults (OWD)** (closed)

| Object | OWD |
|---|---|
| Account | Private |
| Contact | Controlled by Parent |
| Order | Controlled by Parent |
| OrderItem | Controlled by Master-Detail (Order) |
| Product2 | Public Read Only |
| Pricebook2 | Salesforce-managed |
| Product_Family__c | Public Read Only |
| Product_Category__c | Public Read Only |
| Price_Tier__c | Public Read Only |
| Customer_Price__c | Private |
| Credit_History__c | Private |
| Stock_Reservation__c | Private |

Rationale: OWDs set as restrictive as possible and opened with Role Hierarchy/Sharing Rules. Catalog data is universally visible (Public Read Only); customer-territorial data (Account, Order) and sensitive data (Customer_Price__c, Credit_History__c) start Private and open selectively. Reinforces *Trusted* pillar of WAF.

**Derived decision — branch ownership for multi-sucursal accounts**

| Decision | Result |
|---|---|
| Owner of Branch Accounts | Same Sales Rep as the Parent Customer |
| Assignment mechanism | Apex Trigger or Record-Triggered Flow on Branch Account creation; reads owner from Parent_Customer and assigns to Branch |

This enables the Sales Rep owning Don Mario SRL to automatically see all 4 branches via ownership (rather than via Sharing Rules or Apex Sharing).

**Role hierarchy** (closed)

| Decision | Result |
|---|---|
| Structure type | Geographic (territory-based) |
| Hierarchy depth | 4 levels: CEO → Director → Manager → Rep |
| Total roles | 14 (plus System Administrator outside hierarchy) |
| "Grant Access Using Hierarchies" | Enabled (default) for all objects |

Hierarchy tree:

```
CEO / General Director (root)
│
├── Sales Director
│   ├── Sales Manager Norte
│   │   ├── Sales Rep Norte 1
│   │   └── Sales Rep Norte 2
│   └── Sales Manager Sur
│       ├── Sales Rep Sur 1
│       └── Sales Rep Sur 2
│
├── Credit & Risk Manager
│   ├── Credit Analyst 1
│   └── Credit Analyst 2
│
├── Operations Manager
│
├── Catalog Admin Lead
│
└── Finance Manager
```

Rationale: geographic structure is realistic for B2B distributors with physical territory (delivery routes, regional pricing); 4 levels balance manageability with realistic enterprise depth.

**Sharing rules** (closed)

Six criteria-based Sharing Rules opening visibility to non-sales functional areas (Credit, Operations, Finance, Catalog) that sit in parallel branches of the role hierarchy.

| # | Object | Criteria | Recipient (Public Group) | Access |
|---|---|---|---|---|
| 1 | Account | All records | Credit & Risk | Read Only |
| 2 | Credit_History__c | All records | Credit & Risk | Read/Write |
| 3 | Order | Credit_Status = Approved AND Fulfillment_Status NOT IN (Delivered, Cancelled) | Operations | Read/Write |
| 4 | Order | Fulfillment_Status = Delivered AND Payment_Status != Paid | Finance | Read/Write |
| 5 | Customer_Price__c | All records | Catalog Admin | Read/Write |
| 6 | Stock_Reservation__c | Status = Active | Operations | Read/Write |

Public Groups used (instead of direct role assignment): `Credit & Risk`, `Operations`, `Finance`, `Catalog Admin`. Members include roles + subordinates so new hires inherit access automatically. Reinforces *Easy to Change* pillar of WAF.

Ownership inheritance decisions:

| Object | Owner |
|---|---|
| Credit_History__c | Same as related Account (via Apex Trigger or Flow on insert) |
| Customer_Price__c | Sales Rep who negotiated the override (`Negotiated_By__c` field) |
| Stock_Reservation__c | Inherited from related Order via OrderItem |

**External users (Experience Cloud portal)** (closed)

| Decision | Result |
|---|---|
| License type | Customer Community Plus |
| Sharing mechanism | Sharing Sets with "All related Accounts via ACR" |
| External Role Hierarchy | Not used (covered by ACR + Sharing Sets) |
| Base external profile | DistribuYa Customer Portal User |
| External permission tiers | 3: Standard / Branch Manager / Account Owner |

Portal user visibility:

| Object | Portal Account Owner (Don Mario) | Portal Branch Manager (María) | Portal Standard User |
|---|---|---|---|
| Account (own + related via ACR) | Read | Read (only own branch) | Read (only own branch) |
| Contact (own + same account) | Read | Read | Read |
| Order | R/Create | R/Create | R/Create |
| OrderItem | R/Create | R/Create | R/Create |
| Product2, Product_Family__c, Product_Category__c | Read | Read | Read |
| Price_Tier__c | Read | Read | Read |
| Pricebook2 | Read (own segment) | Read | Read |
| Customer_Price__c | Read (own account's overrides) | Read | Read |
| Credit_History__c | **No access** | **No access** | **No access** |
| Stock_Reservation__c | **No access** | **No access** | **No access** |

Rationale: Customer Community Plus is required for multi-branch sharing complexity; ACR-based Sharing Sets natively cover the "Don Mario sees all 4 branches, María sees only Palermo" scenario without External Role Hierarchy. Internal-only data (credit, stock reservations, orchestration runs) hidden from all portal users. Implies licensing cost in production — noted in ADR consequences.

**Permission Sets vs Profiles strategy** (closed)

| Decision | Result |
|---|---|
| Model | Permission Set-led (minimal Profile + atomic Permission Sets + Permission Set Groups) |
| Profile base (internal) | `DistribuYa Internal User` (login hours, IP, locale only) |
| Profile base (external) | `DistribuYa Customer Portal User` (based on Customer Community Plus) |
| Atomic Permission Sets (internal) | 11 |
| Permission Set Groups | 8 (one per role) |
| Atomic Permission Sets (external) | 3 |

Atomic Permission Sets (internal):

| Permission Set | Key permissions |
|---|---|
| `PS - Account Management` | CRUD on Account, Contact; Read Customer_Price__c (own owner) |
| `PS - Order Creation` | Create/Edit Order, OrderItem; Read Pricebook2, Product2 |
| `PS - Order Approval Tier 1` | Approve credit orchestration steps at commercial level |
| `PS - Order Approval Tier 2` | Tier 2 approvals (manager level) |
| `PS - Credit Analyst` | R/W Credit_History__c; Read All on Account credit fields; Tier 3 approvals |
| `PS - Credit Manager` | Above + Edit Credit_Limit__c; escalation approvals |
| `PS - Fulfillment Operations` | Edit Order.Fulfillment_Status; R/W Stock_Reservation__c |
| `PS - Payment Operations` | Edit Order.Payment_Status |
| `PS - Catalog Management` | CRUD on Product2, Product_Family__c, Product_Category__c |
| `PS - Pricing Management` | CRUD on Customer_Price__c, Price_Tier__c; Edit Pricebook2 |
| `PS - Reporting Read All` | View All Data (read-only for Director and above) |

Permission Set Groups (per role):

| PSG | Composition | Assigned to |
|---|---|---|
| `PSG - Sales Rep` | PS Account Management + PS Order Creation + PS Order Approval Tier 1 | Sales Rep roles |
| `PSG - Sales Manager` | PSG Sales Rep + PS Order Approval Tier 2 | Sales Manager roles |
| `PSG - Sales Director` | PSG Sales Manager + PS Reporting Read All | Sales Director |
| `PSG - Credit Analyst` | PS Credit Analyst | Credit Analyst roles |
| `PSG - Credit Manager` | PSG Credit Analyst + PS Credit Manager | Credit Manager |
| `PSG - Operations` | PS Fulfillment Operations + PS Order Creation (read only) | Operations Manager |
| `PSG - Catalog Admin` | PS Catalog Management + PS Pricing Management | Catalog Admin Lead |
| `PSG - Finance` | PS Payment Operations + PS Reporting Read All | Finance Manager |

External Permission Sets:

| Permission Set | Purpose |
|---|---|
| `PS - Portal Standard` | Read catalog, Create Order, Read own Account/Contact |
| `PS - Portal Branch Manager` | Above + Read all Orders of own branch |
| `PS - Portal Account Owner` | Above + Read all related Accounts via ACR (Don Mario level) |

Rationale: Permission Set-led model is Salesforce's official recommendation since 2023. Although Salesforce reversed the Spring '26 enforced EOL of profile permissions in 2024, all product investment remains in Permission Sets and Permission Set Groups. Atomic Permission Sets are composable — a one-off custom role is built by combining existing PSs rather than creating bespoke profiles. Reinforces *Easy to Change* and *Composable* pillars of WAF.

---

## Block B — Closed ✅

All Block B modeling is complete as of 2026-05-30. Summary of what was closed:

- ✅ **Customer domain** — Account (3 Record Types) + Contact (ACR) + credit data + `Credit_History__c`.
- ✅ **Product domain** — Product2 + `Product_Family__c` (variants) + `Product_Category__c` + base Pricebook.
- ✅ **Advanced pricing** — 3 segment Pricebooks + `Customer_Price__c` (override) + `Price_Tier__c` (volume tiers).
- ✅ **Order domain** — Order header, OrderItem, multi-dimensional lifecycle, Flow Orchestration approvals, stock model + reservation + timeout.
- ✅ **Sharing model** — OWD, geographic role hierarchy, sharing rules, external (portal) users, Permission-Set-led security.
- ✅ **Formal ADRs** — 24 candidates consolidated into 7 thematic ADRs ([adr/](../architecture/adr/)).
- ✅ **Final ERD** — Mermaid data model ([diagrams/data-model-erd.md](../architecture/diagrams/data-model-erd.md)).

> **Carried-forward item — RESOLVED in Block D (2026-05-30)**: `Price_Tier__c` link target. ADR-0002 originally chose `PricebookEntry`, but materialization proved the platform **disallows custom lookups to `PricebookEntry`**. Replaced with **`Product2__c` + `Pricebook2__c`** (preserves segment-aware tiers; blank Pricebook2 = global). Also discovered: **lookups to `Product2` cannot be required** (Product2 rejects cascade/restrict, and required lookups need it) → all Product2 lookups are not-required + SetNull, with the "must have a product" rule enforced in app logic. Details in ADR-0002 and the [ERD resolved-items section](../architecture/diagrams/data-model-erd.md).

**Next: Block D — materialization.**

## Pending in Block D (materialization)

- Generación de metadata XML en `force-app/main/default/objects/...` (acá entra Claude Code en serio).
- sfdx-project.json configurado.
- Push a la org Salesforce Developer Edition.
- Primer commit con la org realmente configurada.
