@isTest
public class PartnerDealControllerTest {

    @isTest
    static void testGetPartnerDeals() {

        Account partnerAcc = new Account(
            Name = 'Controller Test Partner'
        );
        insert partnerAcc;

        Account customerAcc = new Account(
            Name = 'Controller Test Customer'
        );
        insert customerAcc;

        Partner_Deal__c deal = new Partner_Deal__c(
            Partner_Account__c = partnerAcc.Id,
            Customer_Account__c = customerAcc.Id,
            Deal_Amount__c = 25000,
            Discount_Percentage__c = 10,
            Status__c = 'Submitted'
        );

        insert deal;

        Test.startTest();

        List<Partner_Deal__c> deals =
            PartnerDealController.getPartnerDeals();

        Test.stopTest();

        System.assertEquals(
            1,
            deals.size(),
            'Expected one Partner Deal.'
        );

        System.assertEquals(
            deal.Id,
            deals[0].Id,
            'Returned Deal Id should match.'
        );

        System.assertEquals(
            'Submitted',
            deals[0].Status__c,
            'Deal Status should be Submitted.'
        );

        System.assertEquals(
            25000,
            deals[0].Deal_Amount__c,
            'Deal Amount should match.'
        );

        System.assertEquals(
            customerAcc.Id,
            deals[0].Customer_Account__c,
            'Customer Account should match.'
        );
    }
}