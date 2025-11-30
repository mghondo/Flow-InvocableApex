/**
 * @description Test class for LeadScorer invocable method
 * @author Portfolio Demonstration
 * @date 2024
 */
@IsTest
private class LeadScorerTest {
    
    /**
     * @description Creates test lead data with various combinations of scoring criteria
     */
    @TestSetup
    static void setupTestData() {
        List<Lead> testLeads = new List<Lead>();
        
        // High-scoring lead: Large company, email, phone, referral source
        testLeads.add(new Lead(
            FirstName = 'John',
            LastName = 'HighScore',
            Company = 'Enterprise Corp',
            NumberOfEmployees = 1500,
            Email = 'john@enterprise.com',
            Phone = '555-1234',
            LeadSource = 'Referral'
        ));
        
        // Medium-scoring lead: Medium company, email, no phone, web source
        testLeads.add(new Lead(
            FirstName = 'Jane',
            LastName = 'MediumScore',
            Company = 'Mid-Size Business',
            NumberOfEmployees = 150,
            Email = 'jane@midsize.com',
            LeadSource = 'Web'
        ));
        
        // Low-scoring lead: Small company, no email, no phone, purchased list
        testLeads.add(new Lead(
            FirstName = 'Bob',
            LastName = 'LowScore',
            Company = 'Small Shop',
            NumberOfEmployees = 3,
            LeadSource = 'Purchased List'
        ));
        
        // Edge case lead: No data provided
        testLeads.add(new Lead(
            FirstName = 'Empty',
            LastName = 'Data',
            Company = 'Unknown Company'
        ));
        
        // Test various company sizes
        testLeads.add(new Lead(
            FirstName = 'Very',
            LastName = 'Large',
            Company = 'Mega Corp',
            NumberOfEmployees = 5000,
            Email = 'contact@mega.com',
            Phone = '555-5000',
            LeadSource = 'Partner Referral'
        ));
        
        testLeads.add(new Lead(
            FirstName = 'Small',
            LastName = 'Business',
            Company = 'Corner Store',
            NumberOfEmployees = 8,
            Email = 'owner@corner.com',
            LeadSource = 'Trade Show'
        ));
        
        // Test different lead sources
        testLeads.add(new Lead(
            FirstName = 'Social',
            LastName = 'Media',
            Company = 'Tech Startup',
            NumberOfEmployees = 25,
            Email = 'social@startup.com',
            Phone = '555-TECH',
            LeadSource = 'Social Media'
        ));
        
        testLeads.add(new Lead(
            FirstName = 'Cold',
            LastName = 'Call',
            Company = 'Random Company',
            NumberOfEmployees = 50,
            Email = 'cold@random.com',
            LeadSource = 'Cold Call'
        ));
        
        insert testLeads;
    }
    
    /**
     * @description Test successful lead scoring with multiple leads
     */
    @IsTest
    static void testCalculateLeadScoresSuccess() {
        // Get test leads
        List<Lead> testLeads = [SELECT Id, FirstName, LastName FROM Lead LIMIT 5];
        
        // Prepare input
        LeadScorer.LeadScoringInput input = new LeadScorer.LeadScoringInput();
        input.leadIds = new List<Id>();
        for (Lead lead : testLeads) {
            input.leadIds.add(lead.Id);
        }
        
        Test.startTest();
        List<LeadScorer.LeadScoringOutput> results = LeadScorer.calculateLeadScores(new List<LeadScorer.LeadScoringInput>{input});
        Test.stopTest();
        
        // Assertions
        System.assertEquals(5, results.size(), 'Should return results for all 5 leads');
        
        for (LeadScorer.LeadScoringOutput result : results) {
            System.assertNotEquals(null, result.leadId, 'Lead ID should not be null');
            System.assertNotEquals(null, result.leadScore, 'Lead score should not be null');
            System.assert(result.leadScore >= 0 && result.leadScore <= 100, 'Score should be between 0-100');
            System.assertNotEquals(null, result.scoreDetails, 'Score details should not be null');
            System.assertNotEquals(null, result.isHighPriority, 'High priority flag should not be null');
        }
    }
    
    /**
     * @description Test high-scoring lead calculation
     */
    @IsTest
    static void testHighScoringLead() {
        Lead highScoreLead = [SELECT Id FROM Lead WHERE FirstName = 'John' AND LastName = 'HighScore' LIMIT 1];
        
        LeadScorer.LeadScoringInput input = new LeadScorer.LeadScoringInput();
        input.leadIds = new List<Id>{highScoreLead.Id};
        
        Test.startTest();
        List<LeadScorer.LeadScoringOutput> results = LeadScorer.calculateLeadScores(new List<LeadScorer.LeadScoringInput>{input});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        LeadScorer.LeadScoringOutput result = results[0];
        
        // High score: 40 (enterprise) + 20 (email) + 15 (phone) + 25 (referral) = 100
        System.assertEquals(100, result.leadScore, 'High-scoring lead should have score of 100');
        System.assertEquals(true, result.isHighPriority, 'High-scoring lead should be high priority');
        System.assert(result.scoreDetails.contains('Company Size: 40'), 'Should include company size score');
        System.assert(result.scoreDetails.contains('Has Email: 20'), 'Should include email score');
        System.assert(result.scoreDetails.contains('Has Phone: 15'), 'Should include phone score');
        System.assert(result.scoreDetails.contains('Referral'), 'Should include lead source details');
    }
    
    /**
     * @description Test low-scoring lead calculation
     */
    @IsTest
    static void testLowScoringLead() {
        Lead lowScoreLead = [SELECT Id FROM Lead WHERE FirstName = 'Bob' AND LastName = 'LowScore' LIMIT 1];
        
        LeadScorer.LeadScoringInput input = new LeadScorer.LeadScoringInput();
        input.leadIds = new List<Id>{lowScoreLead.Id};
        
        Test.startTest();
        List<LeadScorer.LeadScoringOutput> results = LeadScorer.calculateLeadScores(new List<LeadScorer.LeadScoringInput>{input});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        LeadScorer.LeadScoringOutput result = results[0];
        
        // Low score: 5 (small company) + 0 (no email) + 0 (no phone) + 5 (purchased list) = 10
        System.assertEquals(10, result.leadScore, 'Low-scoring lead should have score of 10');
        System.assertEquals(false, result.isHighPriority, 'Low-scoring lead should not be high priority');
    }
    
    /**
     * @description Test empty input handling
     */
    @IsTest
    static void testEmptyInput() {
        LeadScorer.LeadScoringInput input = new LeadScorer.LeadScoringInput();
        input.leadIds = new List<Id>();
        
        Test.startTest();
        List<LeadScorer.LeadScoringOutput> results = LeadScorer.calculateLeadScores(new List<LeadScorer.LeadScoringInput>{input});
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list for empty input');
    }
    
    /**
     * @description Test null input handling
     */
    @IsTest
    static void testNullInput() {
        LeadScorer.LeadScoringInput input = new LeadScorer.LeadScoringInput();
        input.leadIds = null;
        
        Test.startTest();
        List<LeadScorer.LeadScoringOutput> results = LeadScorer.calculateLeadScores(new List<LeadScorer.LeadScoringInput>{input});
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list for null input');
    }
    
    /**
     * @description Test company size scoring logic
     */
    @IsTest
    static void testCompanySizeScoring() {
        List<Lead> testLeads = [SELECT Id FROM Lead WHERE FirstName IN ('Very', 'Small')];
        List<Id> leadIds = new List<Id>();
        for (Lead lead : testLeads) {
            leadIds.add(lead.Id);
        }
        
        LeadScorer.LeadScoringInput input = new LeadScorer.LeadScoringInput();
        input.leadIds = leadIds;
        
        Test.startTest();
        List<LeadScorer.LeadScoringOutput> results = LeadScorer.calculateLeadScores(new List<LeadScorer.LeadScoringInput>{input});
        Test.stopTest();
        
        System.assertEquals(2, results.size(), 'Should return results for both leads');
        
        // Verify different company size scores
        for (LeadScorer.LeadScoringOutput result : results) {
            System.assert(result.scoreDetails.contains('Company Size:'), 'Should include company size in details');
        }
    }
    
    /**
     * @description Test various lead source scoring
     */
    @IsTest
    static void testLeadSourceScoring() {
        List<Lead> testLeads = [SELECT Id, LeadSource FROM Lead WHERE LeadSource IN ('Social Media', 'Cold Call', 'Partner Referral')];
        List<Id> leadIds = new List<Id>();
        for (Lead lead : testLeads) {
            leadIds.add(lead.Id);
        }
        
        LeadScorer.LeadScoringInput input = new LeadScorer.LeadScoringInput();
        input.leadIds = leadIds;
        
        Test.startTest();
        List<LeadScorer.LeadScoringOutput> results = LeadScorer.calculateLeadScores(new List<LeadScorer.LeadScoringInput>{input});
        Test.stopTest();
        
        System.assertEquals(3, results.size(), 'Should return results for all leads');
        
        // Verify lead source scoring is included
        for (LeadScorer.LeadScoringOutput result : results) {
            System.assert(result.scoreDetails.contains('Lead Source'), 'Should include lead source in details');
        }
    }
    
    /**
     * @description Test lead with no data (edge case)
     */
    @IsTest
    static void testLeadWithNoData() {
        Lead emptyLead = [SELECT Id FROM Lead WHERE FirstName = 'Empty' AND LastName = 'Data' LIMIT 1];
        
        LeadScorer.LeadScoringInput input = new LeadScorer.LeadScoringInput();
        input.leadIds = new List<Id>{emptyLead.Id};
        
        Test.startTest();
        List<LeadScorer.LeadScoringOutput> results = LeadScorer.calculateLeadScores(new List<LeadScorer.LeadScoringInput>{input});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        LeadScorer.LeadScoringOutput result = results[0];
        
        // Should have minimal score (0 for most criteria)
        System.assertEquals(0, result.leadScore, 'Lead with no data should have score of 0');
        System.assertEquals(false, result.isHighPriority, 'Lead with no data should not be high priority');
    }
    
    /**
     * @description Test bulk processing with multiple inputs
     */
    @IsTest
    static void testBulkProcessing() {
        List<Lead> testLeads = [SELECT Id FROM Lead LIMIT 8];
        
        // Create multiple inputs to test bulk processing
        List<LeadScorer.LeadScoringInput> inputs = new List<LeadScorer.LeadScoringInput>();
        
        // First input with 3 leads
        LeadScorer.LeadScoringInput input1 = new LeadScorer.LeadScoringInput();
        input1.leadIds = new List<Id>{testLeads[0].Id, testLeads[1].Id, testLeads[2].Id};
        inputs.add(input1);
        
        // Second input with 2 leads
        LeadScorer.LeadScoringInput input2 = new LeadScorer.LeadScoringInput();
        input2.leadIds = new List<Id>{testLeads[3].Id, testLeads[4].Id};
        inputs.add(input2);
        
        // Third input with remaining leads
        LeadScorer.LeadScoringInput input3 = new LeadScorer.LeadScoringInput();
        input3.leadIds = new List<Id>();
        for (Integer i = 5; i < testLeads.size(); i++) {
            input3.leadIds.add(testLeads[i].Id);
        }
        inputs.add(input3);
        
        Test.startTest();
        List<LeadScorer.LeadScoringOutput> results = LeadScorer.calculateLeadScores(inputs);
        Test.stopTest();
        
        System.assertEquals(testLeads.size(), results.size(), 'Should return results for all leads');
        
        // Verify all results have valid data
        for (LeadScorer.LeadScoringOutput result : results) {
            System.assertNotEquals(null, result.leadId, 'All results should have valid lead ID');
            System.assertNotEquals(null, result.leadScore, 'All results should have valid score');
        }
    }
    
    /**
     * @description Test high priority threshold (score >= 70)
     */
    @IsTest
    static void testHighPriorityThreshold() {
        // Query leads that should be close to threshold
        List<Lead> testLeads = [SELECT Id FROM Lead WHERE NumberOfEmployees >= 100];
        
        if (testLeads.isEmpty()) {
            return; // Skip if no suitable test data
        }
        
        LeadScorer.LeadScoringInput input = new LeadScorer.LeadScoringInput();
        input.leadIds = new List<Id>();
        for (Lead lead : testLeads) {
            input.leadIds.add(lead.Id);
        }
        
        Test.startTest();
        List<LeadScorer.LeadScoringOutput> results = LeadScorer.calculateLeadScores(new List<LeadScorer.LeadScoringInput>{input});
        Test.stopTest();
        
        for (LeadScorer.LeadScoringOutput result : results) {
            if (result.leadScore >= 70) {
                System.assertEquals(true, result.isHighPriority, 'Leads with score >= 70 should be high priority');
            } else {
                System.assertEquals(false, result.isHighPriority, 'Leads with score < 70 should not be high priority');
            }
        }
    }
}