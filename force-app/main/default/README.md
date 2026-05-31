# Salesforce Metadata

This directory contains Salesforce metadata in DX (source) format. Block D (materialization) is **in progress** — translating the Phase 1 data model into deployable metadata, domain by domain.

## ⚠️ Manual post-deploy steps (tracked)

- **Account → Credit & Risk sharing rule** (`sharingRules/Account.sharingRules-meta.xml`): blocked by CLI bug (LL-012). The rule file is in source and correct; create it manually in **Setup → Sharing Settings → Account → Sharing Rules** (criteria: `Account Name not equal to (blank)`, share with public group **Credit & Risk**, access **Read Only**), or deploy via mdapi ZIP. The other 5 sharing rules deployed fine via CLI.

## What's materialized so far

### ✅ Customer domain

```
objects/
├── Account/                         (standard object — extended)
│   ├── fields/
│   │   ├── Credit_Limit__c          Currency
│   │   ├── Credit_Used__c           Currency (maintained by automation, Phase 2)
│   │   ├── Payment_Terms__c         Picklist: COD / Net 15 / Net 30 / Net 60
│   │   ├── Segment__c               Picklist: Retailer / Restaurant / Small Business
│   │   ├── Customer_Status__c       Picklist: Active / Inactive / Suspended
│   │   └── Onboarding_Stage__c      Picklist: Initiated / In Validation / Active
│   └── recordTypes/
│       ├── Single_Customer
│       ├── Parent_Customer
│       └── Branch_Customer
└── Credit_History__c/               (custom object — OWD Private)
    ├── Credit_History__c.object-meta.xml
    └── fields/
        ├── Account__c               Lookup → Account (SetNull on delete)
        ├── Change_Timestamp__c      DateTime
        ├── Reason__c                TextArea
        ├── Previous_Limit__c        Currency
        └── New_Limit__c             Currency
```

Traceability: each metadata file references the ADR that justifies it (ADR-0001 for the Account hierarchy/record types, ADR-0003 for credit history).

### ✅ Product domain

```
objects/
├── Product2/                        (standard object — extended)
│   └── fields/
│       ├── Product_Family__c        Lookup → Product_Family__c (required, Restrict delete)
│       ├── Available_Stock__c       Number (synced from ERP)
│       ├── Stock_Last_Sync__c       DateTime
│       └── ERP_Product_ID__c        Text, External Id, Unique
├── Product_Family__c/               (custom object — OWD Public Read Only)
│   └── fields/ Brand__c, Long_Description__c, Image_URL__c,
│              Product_Manager__c (Lookup → User), Product_Category__c (Lookup)
└── Product_Category__c/             (custom object — OWD Public Read Only)
    └── fields/ Display_Order__c, Icon_URL__c, Active__c, Description__c
```

> **Materialization note**: the decisions-log originally specified Product2 → Product_Family__c as **Master-Detail**. This is **impossible on the platform** — a standard object cannot be the detail side of a master-detail ([Salesforce Help](https://help.salesforce.com/s/articleView?id=sf.relationships_considerations.htm&type=5)). Implemented as a **required Lookup with Restrict delete** instead. See decisions-log "Materialization finding".

### ✅ Pricing domain

```
objects/
├── Customer_Price__c/               (custom object — OWD Private)
│   └── fields/ Account__c (LK req Restrict), Product2__c (LK SetNull),
│              Override_Price__c, Effective_Date__c, End_Date__c,
│              Negotiated_By__c (LK User), Notes__c
└── Price_Tier__c/                   (custom object — OWD Public Read Only)
    └── fields/ Product2__c (LK SetNull), Pricebook2__c (LK SetNull, segment-aware),
               Min_Quantity__c, Max_Quantity__c, Tier_Price__c,
               Effective_Date__c, End_Date__c
```

> **Materialization note**: `Price_Tier__c` was intended to Lookup `PricebookEntry`, but the platform disallows custom lookups to PricebookEntry → replaced with `Product2__c` + `Pricebook2__c`. Also, lookups to Product2 can't be required (Product2 rejects cascade/restrict) → all Product2 lookups are not-required + SetNull. See ADR-0002.
> The 3 segment **Pricebooks** themselves are *records/data*, not metadata — created separately.

### ✅ Order domain

```
objects/
├── Order/                           (standard — extended)
│   └── fields/ Order_Type__c, Credit_Status__c, Fulfillment_Status__c,
│              Payment_Status__c, Order_Stage__c (text formula, derived)
├── OrderItem/                       (standard — extended)
│   └── fields/ Applied_Price_Source__c, Price_Modifier_Id__c,
│              Base_Price__c, Discount_Amount__c (currency formula)
├── Stock_Reservation__c/            (custom object — OWD Private)
│   └── fields/ Product2__c (LK SetNull), OrderItem__c (LK SetNull),
│              Quantity__c, Status__c, Expiry_Timestamp__c,
│              Reservation_Reason__c, Released_By__c (LK User), Released_Reason__c
└── Credit_Approval_Tier__mdt/       (Custom Metadata Type)
    └── fields/ Min_Ratio__c (Percent), Max_Ratio__c (Percent), Approver_Role__c
```

### Pending (next)

- **Sharing model** (mostly NOT visible in Schema Builder): record-type assignment, OWD via metadata, public groups, sharing rules, 11 permission sets + 8 permission set groups + 3 external permission sets (ADR-0007).
- **Seed data**: 3 segment Pricebooks + sample `Credit_Approval_Tier__mdt` records (Tier 1/2/3).

## Notes / org-level settings (not file metadata)

- **Account Contact Relationships (ACR)** is enabled via Setup → *Account Settings → Contacts to Multiple Accounts*, an org preference rather than object metadata, so there is no file for it here. Required before the many-to-many Contact model (ADR-0001) works.
- **Record Type visibility** must be granted via permission sets/profiles after deployment — the record type definitions deploy, but users need assignment to see them.

## How to view this metadata

**Right now (no org needed)** — these are plain XML files:
- In **VS Code**: open the `force-app/main/default/objects/` tree. The Salesforce Extension Pack renders them nicely.
- On **GitHub**: browse the same path in the repo.

**Live in a Salesforce org** — once deployed (see below), go to **Setup → Object Manager → Account / Credit History** to see the fields and record types in the UI.

## How to deploy (when you have an org)

```bash
# 1. Authorize an org (Developer Edition or Trailhead Playground). Opens a browser login.
sf org login web --alias distribuya-dev --set-default

# 2. (Optional) Preview what would deploy, without making changes.
sf project deploy preview

# 3. Deploy the metadata to the org.
sf project deploy start

# 4. Open the org in a browser to inspect it.
sf org open
```

If you don't have the Salesforce CLI yet: `npm install -g @salesforce/cli` (or download from developer.salesforce.com/tools/salesforcecli).
