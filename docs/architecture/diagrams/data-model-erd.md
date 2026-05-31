# Data Model — Entity Relationship Diagram (Phase 1)

> **Purpose**: Consolidated ERD of all Phase 1 entities (Customer, Product, Pricing, Order/Stock domains). Synthesis of every modeling decision in [decisions-log.md](../../phase-01/decisions-log.md). **Status: all entities below are deployed and verified live in `distribuya-dev` (Block D).**
>
> **C4 level**: This sits below C3 — it is the logical data model (entity/relationship view), complementary to the C2 Container and C3 Component diagrams. Salesforce Schema Builder covers the physical equivalent; this Mermaid version is the versioned, reviewable source of truth.

## Legend

- **Standard** objects: `Account`, `Contact`, `AccountContactRelation`, `Product2`, `Pricebook2`, `PricebookEntry`, `Order`, `OrderItem`.
- **Custom** objects (`__c`): `Credit_History__c`, `Product_Family__c`, `Product_Category__c`, `Customer_Price__c`, `Price_Tier__c`, `Stock_Reservation__c`.
- **Custom Metadata** (`__mdt`): `Credit_Approval_Tier__mdt` — configuration, not transactional data, so it is **not** drawn as an ERD entity (see note below).
- Relationship notation: `||` one (mandatory), `o{` zero-or-many, `|{` one-or-many, `o|` zero-or-one.
- **MD** = Master-Detail, **LK** = Lookup (annotated on each relationship).

## Diagram

```mermaid
erDiagram
    Account ||--o{ Account : "ParentId (hierarchy, LK)"
    Account }o--o{ Contact : "AccountContactRelation (M:N)"
    Account ||--o{ Credit_History__c : "LK - credit audit trail"
    Account ||--o{ Customer_Price__c : "LK - per-customer overrides"
    Account ||--o{ Order : "places (Branch RT)"

    Order ||--|{ OrderItem : "MD - line items"
    Order }o--|| Pricebook2 : "Pricebook2Id (by Segment)"

    OrderItem }o--|| Product2 : "Product2Id (variant)"

    Product2 }o--|| Product_Family__c : "LK required, Restrict (variant of family)"
    Product_Family__c }o--o| Product_Category__c : "LK - optional category"

    Pricebook2 ||--o{ PricebookEntry : "contains"
    Product2 ||--o{ PricebookEntry : "priced as"

    Customer_Price__c }o--o| Product2 : "LK SetNull - overrides price of"
    Price_Tier__c }o--o| Product2 : "LK SetNull - volume tiers (product)"
    Price_Tier__c }o--o| Pricebook2 : "LK SetNull - segment of tiers"

    Stock_Reservation__c }o--o| OrderItem : "LK SetNull - reserves for"
    Stock_Reservation__c }o--o| Product2 : "LK SetNull - reserves stock of"

    Account {
        RecordType RecordTypeId "Single / Parent / Branch"
        Id ParentId "self - hierarchy"
        Currency Credit_Limit__c "Parent only"
        Currency Credit_Used__c "calculated"
        Picklist Payment_Terms__c "COD / Net15 / Net30 / Net60"
        Picklist Customer_Status__c
        Picklist Segment__c "Retailer / Restaurant / SmallBusiness"
        Picklist Onboarding_Stage__c
    }
    Contact {
        Standard fields "via ACR to many Accounts"
    }
    Credit_History__c {
        Lookup Account__c
        DateTime Change_Timestamp__c
        Text Reason__c
        Currency Previous_Limit__c
        Currency New_Limit__c
    }
    Product2 {
        Lookup Product_Family__c "required, Restrict delete"
        Number Available_Stock__c "synced from ERP"
        DateTime Stock_Last_Sync__c
        Text ERP_Product_ID__c "External Id, unique"
    }
    Product_Family__c {
        Text Brand
        TextArea Long_Description
        Lookup Product_Category__c "optional"
        Url Image_URL
    }
    Product_Category__c {
        Text Name
        Number Display_Order__c
        Url Icon_URL__c
        Checkbox Active__c
        TextArea Description__c
    }
    Pricebook2 {
        Text Name "1 per Segment (3 total)"
    }
    PricebookEntry {
        Lookup Pricebook2Id
        Lookup Product2Id
        Currency UnitPrice
    }
    Customer_Price__c {
        Lookup Account__c
        Lookup Product2__c
        Currency Override_Price__c
        Date Effective_Date__c
        Date End_Date__c
        Lookup Negotiated_By__c "User"
        TextArea Notes__c
    }
    Price_Tier__c {
        Lookup Product2__c "SetNull (PricebookEntry lookup disallowed)"
        Lookup Pricebook2__c "segment-aware, SetNull"
        Number Min_Quantity__c
        Number Max_Quantity__c "nullable for top tier"
        Currency Tier_Price__c
        Date Effective_Date__c
        Date End_Date__c
    }
    Order {
        Lookup AccountId
        Lookup Pricebook2Id
        Picklist Order_Type__c "Standard/Sample/Return/Internal"
        Picklist Status "standard - Draft/Activated"
        Picklist Credit_Status__c
        Picklist Fulfillment_Status__c
        Picklist Payment_Status__c
        Formula Order_Stage__c "derived for UI"
    }
    OrderItem {
        Lookup OrderId "MD"
        Lookup Product2Id
        Picklist Applied_Price_Source__c "Base/Override/Tier"
        Text Price_Modifier_Id__c "soft ref to Customer_Price or Price_Tier"
        Currency Base_Price__c
        Currency Discount_Amount__c "calculated"
    }
    Stock_Reservation__c {
        Lookup Product2__c
        Lookup OrderItem__c "LK not MD - survives deletion"
        Number Quantity__c
        Picklist Status__c "Active/Consumed/Released/Expired"
        DateTime Expiry_Timestamp__c
        Text Reservation_Reason__c
        Lookup Released_By__c
        Text Released_Reason__c
    }
```

## Notes & cross-references

- **`Credit_Approval_Tier__mdt`** (Custom Metadata Type) holds the credit approval matrix (Tier 1 / 2 / 3 with `Min_Ratio__c`, `Max_Ratio__c`, `Approver_Role__c`). It is read by the Flow Orchestration during credit approval. As configuration metadata it is intentionally excluded from the ERD entities.
- **`OrderItem.Price_Modifier_Id__c`** is a *soft* reference (Text) to either `Customer_Price__c` or `Price_Tier__c`, recording which modifier produced the applied price. It is **not** a foreign key, so it is shown as an attribute, not a relationship line. This is deliberate (a single field can point to two different objects for audit purposes).
- **`AccountContactRelation`** is the standard junction object enabling the many-to-many between `Account` and `Contact` (Account Contact Relationships). Drawn here as the `}o--o{` relationship rather than as a separate box, for readability.

## ✅ Resolved modeling items (Block D materialization, 2026-05-30)

These were verified empirically against the org via deploy dry-runs (the platform is the authority, not assumptions):

- **`Price_Tier__c` relationship target — RESOLVED.** Originally intended as a Lookup to **`PricebookEntry`**, but the platform **disallows custom lookups to `PricebookEntry`** (*"referenceTo value of 'PricebookEntry' does not resolve to a valid sObject type"*). Implemented instead as **`Product2__c` + `Pricebook2__c`** (a pair of lookups identifying the same product+segment coordinate). Segment-awareness preserved; blank `Pricebook2__c` = applies across all segments. See ADR-0002.
- **Lookups to `Product2` cannot be required.** `Product2` **cannot be the parent of a cascade/restrict lookup** (*"Cannot add a lookup relationship child with cascade or restrict options to Product2"*), and the platform requires required-lookups to use cascade/restrict. Therefore every lookup *to* `Product2` (`Customer_Price__c.Product2__c`, `Price_Tier__c.Product2__c`, `Stock_Reservation__c.Product2__c`) is **not-required + SetNull**; "must have a product" is enforced by app logic (Phase 2), not the schema.
- **Product2 → Product_Family__c** is a **required Lookup + Restrict** (not Master-Detail): a standard object cannot be the detail side of a master-detail. (This one is *to* a custom object, so Restrict is allowed.)
