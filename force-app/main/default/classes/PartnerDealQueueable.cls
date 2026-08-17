public class PartnerDealQueueable implements Queueable, Database.AllowsCallouts {

    private Id partnerDealId;

    public PartnerDealQueueable(Id partnerDealId) {
        this.partnerDealId = partnerDealId;
    }

    public void execute(QueueableContext context) {

        // ==========================================
        // 1. Get Partner Deal
        // ==========================================

     Partner_Deal__c deal = [
    SELECT Id,
           Name,
           Customer_Account__c,
           Deal_Amount__c,
           Opportunity__c
    FROM Partner_Deal__c
    WHERE Id = :partnerDealId
    LIMIT 1
];
// ==========================================
// Prevent Duplicate Opportunity Creation
// ==========================================

if (deal.Opportunity__c != null) {
    System.debug(
        'Opportunity already exists for Partner Deal: ' +
        deal.Id
    );
    return;
}

        // ==========================================
        // 2. Prepare REST Request
        // ==========================================

        HttpRequest request = new HttpRequest();

        request.setEndpoint(
            'callout:Partner_Deal_API/post'
        );

        request.setMethod('POST');

        request.setHeader(
            'Content-Type',
            'application/json'
        );

        Map<String, Object> requestBody =
            new Map<String, Object>{
                'partnerDealId' => deal.Id,
                'dealName'      => deal.Name,
                'customerId'    => deal.Customer_Account__c,
                'dealAmount'    => deal.Deal_Amount__c
            };

        request.setBody(
            JSON.serialize(requestBody)
        );

        request.setTimeout(10000);

        // ==========================================
        // 3. Execute REST Callout
        // ==========================================

        Http http = new Http();

        HttpResponse response;

        try {

            response = http.send(request);

        } catch (Exception e) {

            System.debug(
                'Partner Deal API Callout Failed: ' +
                e.getMessage()
            );

            return;
        }

        // ==========================================
        // 4. Handle API Response
        // ==========================================

        Integer statusCode = response.getStatusCode();

        if (statusCode >= 200 && statusCode < 300) {

            System.debug(
                'Partner Deal API Success: ' +
                response.getBody()
            );

            // ======================================
            // 5. Create Opportunity
            // ======================================

            Opportunity opp = new Opportunity(
                Name = deal.Name,
                AccountId = deal.Customer_Account__c,
                Amount = deal.Deal_Amount__c,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            );

            insert opp;

            // ==========================================
// Link Opportunity back to Partner Deal
// ==========================================

deal.Opportunity__c = opp.Id;

update deal;

        } else {

            System.debug(
                'Partner Deal API Failed. Status: ' +
                statusCode +
                ', Response: ' +
                response.getBody()
            );
        }
    }
}