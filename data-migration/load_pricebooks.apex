// Recreate DistribuYa pricebook entries in target org, matching by Product Name.
// Rule: standard price must exist before custom prices.

Map<String, Id> prod = new Map<String, Id>();
for (Product2 p : [SELECT Id, Name FROM Product2 WHERE Product_Family__c != null]) {
    prod.put(p.Name, p.Id);
}
System.debug('Products found: ' + prod.size());

Id stdPbId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

Map<String, Id> pb = new Map<String, Id>{ 'Standard Price Book' => stdPbId };
for (String nm : new List<String>{ 'Restaurant', 'Retailer', 'Small Business' }) {
    List<Pricebook2> ex = [SELECT Id FROM Pricebook2 WHERE Name = :nm LIMIT 1];
    if (!ex.isEmpty()) {
        pb.put(nm, ex[0].Id);
    } else {
        Pricebook2 n = new Pricebook2(Name = nm, IsActive = true);
        insert n;
        pb.put(nm, n.Id);
    }
}

// rows: productName, standard, restaurant, retailer, smallBusiness
List<List<Object>> data = new List<List<Object>>{
    new List<Object>{ 'Aceite Vegetal 1L',  1200, 1300, 1200, 1400 },
    new List<Object>{ 'Aceite Vegetal 5L',  5000, 5400, 5000, 5800 },
    new List<Object>{ 'Detergente 900ml',    950, 1000,  950, 1100 },
    new List<Object>{ 'Gaseosa Cola 1.5L',   800,  850,  800,  900 },
    new List<Object>{ 'Gaseosa Cola 2.25L', 1100, 1180, 1100, 1250 }
};

// 1) standard entries first
List<PricebookEntry> stdEntries = new List<PricebookEntry>();
for (List<Object> row : data) {
    Id pid = prod.get((String) row[0]);
    if (pid == null) { continue; }
    stdEntries.add(new PricebookEntry(
        Pricebook2Id = stdPbId, Product2Id = pid,
        UnitPrice = (Decimal) row[1], IsActive = true));
}
insert stdEntries;
System.debug('Standard entries: ' + stdEntries.size());

// 2) custom entries
Map<String, Integer> colByPb = new Map<String, Integer>{
    'Restaurant' => 2, 'Retailer' => 3, 'Small Business' => 4 };
List<PricebookEntry> custEntries = new List<PricebookEntry>();
for (List<Object> row : data) {
    Id pid = prod.get((String) row[0]);
    if (pid == null) { continue; }
    for (String pbName : colByPb.keySet()) {
        custEntries.add(new PricebookEntry(
            Pricebook2Id = pb.get(pbName), Product2Id = pid,
            UnitPrice = (Decimal) row[colByPb.get(pbName)], IsActive = true));
    }
}
insert custEntries;
System.debug('Custom entries: ' + custEntries.size());
System.debug('DONE total PBE: ' + (stdEntries.size() + custEntries.size()));
