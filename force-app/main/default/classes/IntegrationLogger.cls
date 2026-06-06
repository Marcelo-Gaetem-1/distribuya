/**
 * IntegrationLogger — central writer for Integration_Log__c (Phase 4, ADR-0010 / P4-6).
 *
 * Every external integration (ERP, logistics, payments) logs its calls here for audit
 * and dead-letter. Kept simple and bulk-safe: callers build entries, we insert in one DML.
 *
 * `without sharing`: integration logging is system-level bookkeeping; it must succeed
 * regardless of the running user's record access. (Logs are OWD Private; access granted via PS.)
 */
public without sharing class IntegrationLogger {

    public enum Direction { OUTBOUND, INBOUND }
    public enum Status { SUCCESS, FAILED, RETRYING, DEAD_LETTER }

    /** Fluent entry builder so callers read clearly. */
    public class Entry {
        Integration_Log__c rec = new Integration_Log__c();
        public Entry system(String sys)        { rec.System__c = sys; return this; }
        public Entry direction(Direction d)    { rec.Direction__c = d.name(); return this; }
        public Entry status(Status s)          { rec.Status__c = statusApiName(s); return this; }
        public Entry endpoint(String e)        { rec.Endpoint__c = clip(e, 255); return this; }
        public Entry request(String body)      { rec.Request_Payload__c = clip(body, 32768); return this; }
        public Entry response(String body)     { rec.Response_Payload__c = clip(body, 32768); return this; }
        public Entry error(String msg)         { rec.Error_Message__c = clip(msg, 4000); return this; }
        public Entry retryCount(Integer n)     { rec.Retry_Count__c = n; return this; }
        public Entry relatedTo(Id recordId)    { rec.Related_Record_Id__c = recordId; return this; }
        public Integration_Log__c build()      { return rec; }
    }

    public static Entry entry() { return new Entry(); }

    /** Insert a single log entry. */
    public static Integration_Log__c log(Entry e) {
        Integration_Log__c rec = e.build();
        insert rec;
        return rec;
    }

    /** Bulk insert. */
    public static void logAll(List<Entry> entries) {
        if (entries == null || entries.isEmpty()) return;
        List<Integration_Log__c> recs = new List<Integration_Log__c>();
        for (Entry e : entries) recs.add(e.build());
        insert recs;
    }

    /** Map the enum to the exact Status__c picklist API value. */
    private static String statusApiName(Status s) {
        if (s == Status.SUCCESS)     return 'Success';
        if (s == Status.FAILED)      return 'Failed';
        if (s == Status.RETRYING)    return 'Retrying';
        if (s == Status.DEAD_LETTER) return 'Dead_Letter';
        return 'Failed';
    }

    private static String clip(String v, Integer max) {
        if (v == null) return null;
        return v.length() > max ? v.substring(0, max) : v;
    }
}
