/**
 * IntegrationLoggerTest — verifies the integration audit logger writes correctly,
 * maps statuses to the right picklist values, clips long fields, and bulk-inserts.
 */
@isTest
private class IntegrationLoggerTest {

    @isTest
    static void log_singleEntry_writesAllFields() {
        Account a = TestDataFactory.newAccount('Test Co', 'Retailer');

        Test.startTest();
        Integration_Log__c rec = IntegrationLogger.log(
            IntegrationLogger.entry()
                .system('ERP')
                .direction(IntegrationLogger.Direction.OUTBOUND)
                .status(IntegrationLogger.Status.SUCCESS)
                .endpoint('callout:ERP/orders')
                .request('{"orderId":"x"}')
                .response('{"ok":true}')
                .retryCount(0)
                .relatedTo(a.Id)
        );
        Test.stopTest();

        Integration_Log__c saved = [
            SELECT System__c, Direction__c, Status__c, Endpoint__c, Request_Payload__c,
                   Response_Payload__c, Retry_Count__c, Related_Record_Id__c
            FROM Integration_Log__c WHERE Id = :rec.Id
        ];
        System.assertEquals('ERP', saved.System__c);
        System.assertEquals('Outbound', saved.Direction__c);
        System.assertEquals('Success', saved.Status__c);
        System.assertEquals('callout:ERP/orders', saved.Endpoint__c);
        System.assertEquals(0, saved.Retry_Count__c);
        System.assertEquals(a.Id, saved.Related_Record_Id__c);
    }

    @isTest
    static void status_deadLetter_mapsToApiValue() {
        Test.startTest();
        Integration_Log__c rec = IntegrationLogger.log(
            IntegrationLogger.entry().system('ERP')
                .direction(IntegrationLogger.Direction.OUTBOUND)
                .status(IntegrationLogger.Status.DEAD_LETTER)
                .error('gave up after retries')
        );
        Test.stopTest();
        Integration_Log__c saved = [SELECT Status__c, Error_Message__c FROM Integration_Log__c WHERE Id = :rec.Id];
        System.assertEquals('Dead_Letter', saved.Status__c, 'Enum must map to picklist API value');
        System.assertEquals('gave up after retries', saved.Error_Message__c);
    }

    @isTest
    static void longFields_areClipped() {
        String big = 'x'.repeat(40000); // > 32768
        Test.startTest();
        Integration_Log__c rec = IntegrationLogger.log(
            IntegrationLogger.entry().system('ERP')
                .direction(IntegrationLogger.Direction.INBOUND)
                .status(IntegrationLogger.Status.FAILED)
                .request(big)
        );
        Test.stopTest();
        Integration_Log__c saved = [SELECT Request_Payload__c FROM Integration_Log__c WHERE Id = :rec.Id];
        System.assertEquals(32768, saved.Request_Payload__c.length(), 'Should clip to field max');
    }

    @isTest
    static void logAll_bulkInserts() {
        List<IntegrationLogger.Entry> entries = new List<IntegrationLogger.Entry>();
        for (Integer i = 0; i < 50; i++) {
            entries.add(IntegrationLogger.entry().system('ERP')
                .direction(IntegrationLogger.Direction.OUTBOUND)
                .status(IntegrationLogger.Status.SUCCESS));
        }
        Test.startTest();
        IntegrationLogger.logAll(entries);
        Test.stopTest();
        System.assertEquals(50, [SELECT COUNT() FROM Integration_Log__c]);
    }

    @isTest
    static void logAll_emptyIsSafe() {
        Test.startTest();
        IntegrationLogger.logAll(new List<IntegrationLogger.Entry>());
        IntegrationLogger.logAll(null);
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM Integration_Log__c]);
    }
}
