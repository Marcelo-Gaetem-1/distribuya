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
