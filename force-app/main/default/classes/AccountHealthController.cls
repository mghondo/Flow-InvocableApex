public with sharing class AccountHealthController {
    @AuraEnabled(cacheable=true)
    public static AccountHealthData getAccountHealth(Id accountId) {
        AccountHealthData healthData = new AccountHealthData();
        
        // Get Account info
        Account acc = [
            SELECT Id, Name, LastActivityDate 
            FROM Account 
            WHERE Id = :accountId 
            LIMIT 1
        ];
        healthData.accountName = acc.Name;
        healthData.lastActivityDate = acc.LastActivityDate;
        
        // Count Open Opportunities
        healthData.openOpportunities = [
            SELECT COUNT() 
            FROM Opportunity 
            WHERE AccountId = :accountId 
            AND IsClosed = false
        ];
        
        // Count Won Opportunities (last 12 months)
        healthData.wonOpportunities = [
            SELECT COUNT() 
            FROM Opportunity 
            WHERE AccountId = :accountId 
            AND IsWon = true 
            AND CloseDate >= LAST_N_DAYS:365
        ];
        
        // Count Open Cases
        healthData.openCases = [
            SELECT COUNT() 
            FROM Case 
            WHERE AccountId = :accountId 
            AND IsClosed = false
        ];
        
        // Calculate health score (simple algorithm)
        healthData.healthScore = calculateHealthScore(healthData);
        
        return healthData;
    }
    
    private static Integer calculateHealthScore(AccountHealthData data) {
        Integer score = 50; // Base score
        
        // Recent activity boosts score
        if (data.lastActivityDate != null) {
            Integer daysSinceActivity = data.lastActivityDate.daysBetween(Date.today());
            if (daysSinceActivity <= 7) score += 20;
            else if (daysSinceActivity <= 30) score += 10;
            else if (daysSinceActivity > 90) score -= 20;
        } else {
            score -= 10;
        }
        
        // Open opportunities boost score
        if (data.openOpportunities > 0) score += 15;
        
        // Won opportunities boost score
        if (data.wonOpportunities > 0) score += 15;
        
        // Open cases reduce score
        if (data.openCases > 3) score -= 15;
        else if (data.openCases > 0) score -= 5;
        
        // Keep score in bounds
        return Math.max(0, Math.min(100, score));
    }
    
    public class AccountHealthData {
        @AuraEnabled public String accountName;
        @AuraEnabled public Date lastActivityDate;
        @AuraEnabled public Integer openOpportunities;
        @AuraEnabled public Integer wonOpportunities;
        @AuraEnabled public Integer openCases;
        @AuraEnabled public Integer healthScore;
    }
}