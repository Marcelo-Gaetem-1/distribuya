// Link Don Mario orders to the portal contact so "Get Orders By Contact" finds them
Id c = [SELECT Id FROM Contact WHERE Email = 'marcelogaetemunoz1@gmail.com' LIMIT 1].Id;
List<Order> os = [SELECT Id FROM Order WHERE Account.Name = 'Don Mario - Palermo'];
for (Order o : os) { o.BillToContactId = c; }
update os;
System.debug('Linked ' + os.size() + ' orders to contact ' + c);
