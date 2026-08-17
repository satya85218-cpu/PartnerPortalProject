@isTest
public class PartnerDealServiceTest {

    // =========================================================
    // Test 1: Submitted Deal Success
    // =========================================================
    @isTest
    static void testSubmittedDealSuccess() {

        Account partnerAcc = new Account(
            Name = 'ABC Technologies Pvt Ltd'
        );
        insert partnerAcc;

        Account customerAcc = new Account(
            Name = 'Customer XYZ'
        );
        insert customerAcc;

        Partner_Deal__c deal = new Partner_Deal__c(
            Partner_Account__c = partnerAcc.Id,
            Customer_Account__c = customerAcc.Id,
            Deal_Amount__c = 100000,
            Discount_Percentage__c = 20,
            Status__c = 'Submitted'
        );

        Test.startTest();

        insert deal;

        Test.stopTest();

        Partner_Deal__c savedDeal = [
            SELECT Submitted_Date__c
            FROM Partner_Deal__c
            WHERE Id = :deal.Id
        ];

        System.assertNotEquals(
            null,
            savedDeal.Submitted_Date__c,
            'Submitted Date should be populated.'
        );
    }


    // =========================================================
    // Test 2: Duplicate Partner Deal
    // =========================================================
    @isTest
    static void testDuplicatePartnerDeal() {

        Account partnerAcc = new Account(
            Name = 'Partner A'
        );
        insert partnerAcc;

        Account customerAcc = new Account(
            Name = 'Customer ABC'
        );
        insert customerAcc;

        Partner_Deal__c firstDeal = new Partner_Deal__c(
            Partner_Account__c = partnerAcc.Id,
            Customer_Account__c = customerAcc.Id,
            Deal_Amount__c = 50000,
            Discount_Percentage__c = 10,
            Status__c = 'Submitted'
        );

        insert firstDeal;

        Partner_Deal__c secondDeal = new Partner_Deal__c(
            Partner_Account__c = partnerAcc.Id,
            Customer_Account__c = customerAcc.Id,
            Deal_Amount__c = 6000,
            Discount_Percentage__c = 15,
            Status__c = 'Submitted'
        );

        Test.startTest();

        Database.SaveResult sr = Database.insert(
            secondDeal,
            false
        );

        Test.stopTest();

        System.assertEquals(
            false,
            sr.isSuccess()
        );

        System.assert(
            sr.getErrors()[0].getMessage().contains(
                'An active Partner Deal already exists'
            )
        );
    }


    // =========================================================
    // Test 3: Opportunity Creation After Approval
    // =========================================================
    @isTest
    static void testOpportunityCreation() {

        Account partnerAcc = new Account(
            Name = 'Partner Company'
        );
        insert partnerAcc;

        Account customerAcc = new Account(
            Name = 'Customer Company'
        );
        insert customerAcc;

        Partner_Deal__c deal = new Partner_Deal__c(
            Partner_Account__c = partnerAcc.Id,
            Customer_Account__c = customerAcc.Id,
            Deal_Amount__c = 7500,
            Discount_Percentage__c = 15,
            Status__c = 'Submitted',
            Approval_Status__c = 'Not Submitted'
        );

        insert deal;

        // Mock REST API success response
        Test.setMock(
            HttpCalloutMock.class,
            new PartnerDealCalloutMock()
        );

        Test.startTest();

        deal.Approval_Status__c = 'Approved';
        update deal;

        Test.stopTest();

        // Verify Opportunity was created
        List<Opportunity> opps = [
            SELECT
                Id,
                Name,
                AccountId,
                Amount,
                StageName,
                CloseDate
            FROM Opportunity
            WHERE AccountId = :customerAcc.Id
        ];

        System.assertEquals(
            1,
            opps.size(),
            'One Opportunity should be created after approval.'
        );

        System.assertEquals(
            deal.Deal_Amount__c,
            opps[0].Amount,
            'Opportunity Amount should match Deal Amount.'
        );

        System.assertEquals(
            customerAcc.Id,
            opps[0].AccountId,
            'Opportunity Account should match Customer Account.'
        );

        System.assertEquals(
            'Prospecting',
            opps[0].StageName,
            'Opportunity Stage should be Prospecting.'
        );

        System.assertEquals(
            Date.today().addDays(30),
            opps[0].CloseDate,
            'Opportunity Close Date should be 30 days from today.'
        );

        // Verify Approval Audit Fields
        Partner_Deal__c updatedDeal = [
            SELECT
                Approved_By__c,
                Approved_Date__c
            FROM Partner_Deal__c
            WHERE Id = :deal.Id
        ];

        System.assertNotEquals(
            null,
            updatedDeal.Approved_By__c,
            'Approved By should be populated.'
        );

        System.assertNotEquals(
            null,
            updatedDeal.Approved_Date__c,
            'Approved Date should be populated.'
        );
    }


    // =========================================================
    // Test 4: Invalid Deal Amount
    // =========================================================
    @isTest
    static void testInvalidDealAmount() {

        Account partnerAcc = new Account(
            Name = 'Test Partner'
        );
        insert partnerAcc;

        Account customerAcc = new Account(
            Name = 'Test Customer'
        );
        insert customerAcc;

        Partner_Deal__c deal = new Partner_Deal__c(
            Partner_Account__c = partnerAcc.Id,
            Customer_Account__c = customerAcc.Id,
            Deal_Amount__c = 0,
            Discount_Percentage__c = 10,
            Status__c = 'Submitted'
        );

        Test.startTest();

        Database.SaveResult sr = Database.insert(
            deal,
            false
        );

        Test.stopTest();

        System.assertEquals(
            false,
            sr.isSuccess(),
            'Deal with Zero amount should not be inserted.'
        );

        System.assert(
            sr.getErrors()[0].getMessage().contains(
                'Deal Amount must be greater than zero.'
            ),
            'Expected Deal Amount validation error.'
        );
    }


    // =========================================================
    // Test 5: Discount Greater Than 30%
    // =========================================================
    @isTest
    static void testDiscountGreaterThan30() {

        Account partnerAcc = new Account(
            Name = 'Discount Test Partner'
        );
        insert partnerAcc;

        Account customerAcc = new Account(
            Name = 'Discount Test Customer'
        );
        insert customerAcc;

        Partner_Deal__c deal = new Partner_Deal__c(
            Partner_Account__c = partnerAcc.Id,
            Customer_Account__c = customerAcc.Id,
            Deal_Amount__c = 10000,
            Discount_Percentage__c = 35,
            Status__c = 'Submitted'
        );

        Test.startTest();

        Database.SaveResult sr = Database.insert(
            deal,
            false
        );

        Test.stopTest();

        System.assertEquals(
            false,
            sr.isSuccess(),
            'Deal with discount greater than 30% should not be inserted.'
        );

        System.assert(
            sr.getErrors()[0].getMessage().contains(
                'Discount Percentage cannot exceed 30%.'
            ),
            'Expected Discount Percentage validation error.'
        );
    }


    // =========================================================
    // Test 6: Missing Partner Account
    // =========================================================
    @isTest
    static void testMissingPartnerAccount() {

        Account customerAcc = new Account(
            Name = 'Missing Partner Customer'
        );
        insert customerAcc;

        Partner_Deal__c deal = new Partner_Deal__c(
            Customer_Account__c = customerAcc.Id,
            Deal_Amount__c = 10000,
            Discount_Percentage__c = 10,
            Status__c = 'Submitted'
        );

        Test.startTest();

        Database.SaveResult sr = Database.insert(
            deal,
            false
        );

        Test.stopTest();

        System.assertEquals(
            false,
            sr.isSuccess(),
            'Deal without Partner Account should not be inserted.'
        );

        System.assert(
            sr.getErrors()[0].getMessage().contains(
                'Partner Account is required when submitting a deal.'
            ),
            'Expected Partner Account validation error.'
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
}