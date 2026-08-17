@isTest
private class PartnerDealQueueableTest {

    // =========================================================
    // Test 1: Opportunity Creation - Successful REST Callout
    // =========================================================
    @isTest
    static void testOpportunityCreationForApprovedDeal() {

        // 1. Create Customer Account
        Account customerAccount = new Account(
            Name = 'Test Customer Account'
        );
        insert customerAccount;

        // 2. Create Partner Deal
        Partner_Deal__c deal = new Partner_Deal__c(
            Customer_Account__c = customerAccount.Id,
            Deal_Amount__c = 100000
        );
        insert deal;

        // 3. Mock successful REST response
        Test.setMock(
            HttpCalloutMock.class,
            new PartnerDealCalloutMock()
        );

        // 4. Execute Queueable
        Test.startTest();

        System.enqueueJob(
            new PartnerDealQueueable(deal.Id)
        );

        Test.stopTest();

        // 5. Verify Opportunity was created
        Opportunity createdOpportunity = [
            SELECT
                Id,
                Name,
                AccountId,
                Amount,
                StageName,
                CloseDate
            FROM Opportunity
            WHERE AccountId = :customerAccount.Id
            LIMIT 1
        ];

        // 6. Assertions
        System.assertEquals(
            customerAccount.Id,
            createdOpportunity.AccountId,
            'Opportunity Account should match Customer Account.'
        );

        System.assertEquals(
            100000,
            createdOpportunity.Amount,
            'Opportunity Amount should match Deal Amount.'
        );

        System.assertEquals(
            'Prospecting',
            createdOpportunity.StageName,
            'Opportunity Stage should be Prospecting.'
        );

        System.assertEquals(
            Date.today().addDays(30),
            createdOpportunity.CloseDate,
            'Opportunity Close Date should be 30 days from today.'
        );

        // 7. Verify Partner Deal is linked to Opportunity
        Partner_Deal__c updatedDeal = [
            SELECT Opportunity__c
            FROM Partner_Deal__c
            WHERE Id = :deal.Id
        ];

        System.assertEquals(
            createdOpportunity.Id,
            updatedDeal.Opportunity__c,
            'Partner Deal should be linked to the created Opportunity.'
        );
    }


    // =========================================================
    // Test 2: REST Callout Failure
    // =========================================================
    @isTest
    static void testCalloutFailureHandling() {

        // 1. Create Customer Account
        Account customerAccount = new Account(
            Name = 'Test Error Customer Account'
        );
        insert customerAccount;

        // 2. Create Partner Deal
        Partner_Deal__c deal = new Partner_Deal__c(
            Customer_Account__c = customerAccount.Id,
            Deal_Amount__c = 50000
        );
        insert deal;

        // 3. Mock HTTP 500 response
        Test.setMock(
            HttpCalloutMock.class,
            new PartnerDealCalloutErrorMock()
        );

        // 4. Execute Queueable
        Test.startTest();

        System.enqueueJob(
            new PartnerDealQueueable(deal.Id)
        );

        Test.stopTest();

        // 5. Verify Opportunity was NOT created
        List<Opportunity> opportunities = [
            SELECT Id
            FROM Opportunity
            WHERE AccountId = :customerAccount.Id
        ];

        System.assertEquals(
            0,
            opportunities.size(),
            'Opportunity should not be created when REST API returns an error.'
        );
    }


    // =========================================================
    // Test 3: Existing Opportunity Prevents Duplicate
    // =========================================================
    @isTest
    static void testExistingOpportunityPreventsDuplicate() {

        // 1. Create Customer Account
        Account customerAccount = new Account(
            Name = 'Existing Opportunity Customer'
        );
        insert customerAccount;

        // 2. Create existing Opportunity
        Opportunity existingOpp = new Opportunity(
            Name = 'Existing Partner Deal Opportunity',
            AccountId = customerAccount.Id,
            Amount = 75000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert existingOpp;

        // 3. Create Partner Deal already linked to Opportunity
        Partner_Deal__c deal = new Partner_Deal__c(
            Customer_Account__c = customerAccount.Id,
            Deal_Amount__c = 75000,
            Opportunity__c = existingOpp.Id
        );
        insert deal;

        // 4. Mock REST callout
        Test.setMock(
            HttpCalloutMock.class,
            new PartnerDealCalloutMock()
        );

        // 5. Execute Queueable
        Test.startTest();

        System.enqueueJob(
            new PartnerDealQueueable(deal.Id)
        );

        Test.stopTest();

        // 6. Verify only one Opportunity exists
        List<Opportunity> opportunities = [
            SELECT Id
            FROM Opportunity
            WHERE AccountId = :customerAccount.Id
        ];

        System.assertEquals(
            1,
            opportunities.size(),
            'A duplicate Opportunity should not be created.'
        );

        System.assertEquals(
            existingOpp.Id,
            opportunities[0].Id,
            'The existing Opportunity should remain unchanged.'
        );
    }


    // =========================================================
    // HTTP Mock: Successful REST API Response
    // =========================================================
    private class PartnerDealCalloutMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest request) {

            HttpResponse response = new HttpResponse();

            response.setStatusCode(200);

            response.setHeader(
                'Content-Type',
                'application/json'
            );

            response.setBody(
                '{"success":true,"message":"Partner Deal received"}'
            );

            return response;
        }
    }


    // =========================================================
    // HTTP Mock: Error REST API Response
    // =========================================================
    private class PartnerDealCalloutErrorMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest request) {

            HttpResponse response = new HttpResponse();

            response.setStatusCode(500);

            response.setHeader(
                'Content-Type',
                'application/json'
            );

            response.setBody(
                '{"success":false,"message":"Internal Server Error"}'
            );

            return response;
        }
    }
}