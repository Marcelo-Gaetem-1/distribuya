// Enable Don Mario - Palermo as a B2B Commerce buyer (LL-028: two-step activation)
Id acctId = [SELECT Id FROM Account WHERE Name = 'Don Mario - Palermo' LIMIT 1].Id;
Id bgId   = [SELECT Id FROM BuyerGroup LIMIT 1].Id;

// 1) BuyerAccount with status Active
BuyerAccount ba = new BuyerAccount(BuyerId = acctId, Name = 'Don Mario - Palermo', BuyerStatus = 'Active');
insert ba;
// 2) activate
ba.IsActive = true;
update ba;
// 3) add to buyer group
insert new BuyerGroupMember(BuyerGroupId = bgId, BuyerId = acctId);
System.debug('Buyer enabled: ' + acctId + ' in group ' + bgId);
