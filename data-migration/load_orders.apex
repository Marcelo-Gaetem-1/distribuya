// Recreate DistribuYa orders + line items in target org, matching by names.
Id acctId = [SELECT Id FROM Account WHERE Name = 'Don Mario - Palermo' LIMIT 1].Id;

Map<String, Id> pbByName = new Map<String, Id>();
for (Pricebook2 p : [SELECT Id, Name FROM Pricebook2]) { pbByName.put(p.Name, p.Id); }

Map<String, Id> pbe = new Map<String, Id>(); // key: pricebook|product
for (PricebookEntry e : [SELECT Id, Pricebook2.Name, Product2.Name FROM PricebookEntry WHERE Product2.Product_Family__c != null]) {
    pbe.put(e.Pricebook2.Name + '|' + e.Product2.Name, e.Id);
}

Date d1 = Date.newInstance(2026, 5, 31);
Date d2 = Date.newInstance(2026, 6, 5);

Order o1 = new Order(AccountId=acctId, EffectiveDate=d1, Status='Draft', Credit_Status__c='Approved',     Pricebook2Id=pbByName.get('Retailer'));
Order o2 = new Order(AccountId=acctId, EffectiveDate=d2, Status='Draft', Credit_Status__c='Not_Required', Pricebook2Id=pbByName.get('Small Business'));
Order o3 = new Order(AccountId=acctId, EffectiveDate=d2, Status='Draft', Credit_Status__c='Not_Required', Pricebook2Id=pbByName.get('Small Business'));
Order o4 = new Order(AccountId=acctId, EffectiveDate=d2, Status='Draft', Credit_Status__c='Approved',     Pricebook2Id=pbByName.get('Small Business'));
insert new List<Order>{ o1, o2, o3, o4 };

List<OrderItem> items = new List<OrderItem>{
    new OrderItem(OrderId=o1.Id, PricebookEntryId=pbe.get('Retailer|Aceite Vegetal 5L'),       Quantity=10, UnitPrice=5000),
    new OrderItem(OrderId=o2.Id, PricebookEntryId=pbe.get('Small Business|Aceite Vegetal 1L'),  Quantity=1,  UnitPrice=1400),
    new OrderItem(OrderId=o3.Id, PricebookEntryId=pbe.get('Small Business|Aceite Vegetal 5L'),  Quantity=1,  UnitPrice=5800),
    new OrderItem(OrderId=o3.Id, PricebookEntryId=pbe.get('Small Business|Aceite Vegetal 1L'),  Quantity=2,  UnitPrice=1400),
    new OrderItem(OrderId=o4.Id, PricebookEntryId=pbe.get('Small Business|Detergente 900ml'),   Quantity=1,  UnitPrice=1100)
};
insert items;
System.debug('Orders: 4  Items: ' + items.size());
