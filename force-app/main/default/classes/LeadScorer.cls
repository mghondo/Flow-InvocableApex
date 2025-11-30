/**
 * @description Invocable Apex class that calculates lead scores based on multiple criteria
 * @author Portfolio Demonstration
 * @date 2024
 */
public with sharing class LeadScorer {
    
    /**
     * @description Input wrapper class for the invocable method
     */
    public class LeadScoringInput {
        @InvocableVariable(label='Lead IDs' description='List of Lead record IDs to score' required=true)
        public List<Id> leadIds;
    }
    
    /**
     * @description Output wrapper class for the invocable method
     */
    public class LeadScoringOutput {
        @InvocableVariable(label='Lead ID' description='The Lead record ID')
        public Id leadId;
        
        @InvocableVariable(label='Lead Score' description='Calculated lead score (0-100)')
        public Decimal leadScore;
        
        @InvocableVariable(label='Score Details' description='Breakdown of scoring criteria')
        public String scoreDetails;
        
        @InvocableVariable(label='Is High Priority' description='Whether this lead is considered high priority (score >= 70)')
        public Boolean isHighPriority;
    }
    
    /**
     * @description Invocable method to calculate lead scores
     * @param inputs List of input parameters containing Lead IDs
     * @return List of LeadScoringOutput with calculated scores
     */
    @InvocableMethod(label='Calculate Lead Scores' description='Calculates lead scores based on company size, contact info, and lead source')
    public static List<LeadScoringOutput> calculateLeadScores(List<LeadScoringInput> inputs) {
        List<LeadScoringOutput> results = new List<LeadScoringOutput>();
        
        // Collect all Lead IDs from inputs
        Set<Id> allLeadIds = new Set<Id>();
        for (LeadScoringInput input : inputs) {
            if (input.leadIds != null) {
                allLeadIds.addAll(input.leadIds);
            }
        }
        
        if (allLeadIds.isEmpty()) {
            return results;
        }
        
        // Query leads with required fields for scoring
        Map<Id, Lead> leadsMap = new Map<Id, Lead>([
            SELECT Id, Name, NumberOfEmployees, Email, Phone, LeadSource, Company
            FROM Lead 
            WHERE Id IN :allLeadIds
        ]);
        
        // Calculate scores for each requested lead
        for (Id leadId : allLeadIds) {
            Lead currentLead = leadsMap.get(leadId);
            if (currentLead != null) {
                LeadScoringOutput output = calculateIndividualLeadScore(currentLead);
                results.add(output);
            }
        }
        
        return results;
    }
    
    /**
     * @description Calculates score for an individual lead
     * @param lead The Lead record to score
     * @return LeadScoringOutput with calculated score and details
     */
    private static LeadScoringOutput calculateIndividualLeadScore(Lead lead) {
        LeadScoringOutput output = new LeadScoringOutput();
        output.leadId = lead.Id;
        
        Decimal score = 0;
        List<String> scoreBreakdown = new List<String>();
        
        // Company Size Scoring (0-40 points)
        Decimal companySizeScore = calculateCompanySizeScore(lead.NumberOfEmployees);
        score += companySizeScore;
        scoreBreakdown.add('Company Size: ' + companySizeScore + ' pts');
        
        // Email Present (0-20 points)
        Decimal emailScore = String.isNotBlank(lead.Email) ? 20 : 0;
        score += emailScore;
        scoreBreakdown.add('Has Email: ' + emailScore + ' pts');
        
        // Phone Present (0-15 points)
        Decimal phoneScore = String.isNotBlank(lead.Phone) ? 15 : 0;
        score += phoneScore;
        scoreBreakdown.add('Has Phone: ' + phoneScore + ' pts');
        
        // Lead Source Scoring (0-25 points)
        Decimal leadSourceScore = calculateLeadSourceScore(lead.LeadSource);
        score += leadSourceScore;
        scoreBreakdown.add('Lead Source (' + (lead.LeadSource ?? 'None') + '): ' + leadSourceScore + ' pts');
        
        output.leadScore = score;
        output.scoreDetails = String.join(scoreBreakdown, '; ');
        output.isHighPriority = score >= 70;
        
        return output;
    }
    
    /**
     * @description Calculates score based on company size
     * @param numberOfEmployees Number of employees in the company
     * @return Score between 0-40 based on company size
     */
    private static Decimal calculateCompanySizeScore(Integer numberOfEmployees) {
        if (numberOfEmployees == null) {
            return 0;
        }
        
        if (numberOfEmployees >= 1000) {
            return 40; // Enterprise
        } else if (numberOfEmployees >= 100) {
            return 30; // Large business
        } else if (numberOfEmployees >= 25) {
            return 20; // Medium business
        } else if (numberOfEmployees >= 5) {
            return 10; // Small business
        } else {
            return 5; // Very small business
        }
    }
    
    /**
     * @description Calculates score based on lead source
     * @param leadSource The source of the lead
     * @return Score between 0-25 based on lead source quality
     */
    private static Decimal calculateLeadSourceScore(String leadSource) {
        if (String.isBlank(leadSource)) {
            return 0;
        }
        
        // High-quality sources
        if (leadSource.equalsIgnoreCase('Referral') || 
            leadSource.equalsIgnoreCase('Partner Referral')) {
            return 25;
        }
        
        // Medium-quality sources
        if (leadSource.equalsIgnoreCase('Web') || 
            leadSource.equalsIgnoreCase('Trade Show') ||
            leadSource.equalsIgnoreCase('Webinar')) {
            return 20;
        }
        
        // Lower-quality sources
        if (leadSource.equalsIgnoreCase('Email Campaign') ||
            leadSource.equalsIgnoreCase('Social Media')) {
            return 15;
        }
        
        // Purchased/cold sources
        if (leadSource.equalsIgnoreCase('Purchased List') ||
            leadSource.equalsIgnoreCase('Cold Call')) {
            return 5;
        }
        
        // Default for other sources
        return 10;
    }
}