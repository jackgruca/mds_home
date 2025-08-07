# Asset Valuation Logic Breakdown

## **Current Player Value Calculation**

### **Step 1: Get Player Percentile** 
```dart
double playerPercentile = _getPlayerPercentile(player);
```
- **Source**: Position rankings CSV (QB/RB/WR/TE) or fallback to `overallRating/100`
- **Example**: Mahomes in QB rankings has `myRank = 0.936` → 93.6th percentile
- **Fallback**: If not in rankings, use `overallRating = 92` → 92nd percentile

### **Step 2: Get Position Contracts**
```dart
List<ContractInfo> positionContracts = _getPositionContracts(player.position);
```
- **Source**: Real NFL contract data (47K+ contracts)
- **Example**: QB contracts sorted by AAV: Dak ($60M), Burrow ($55M), Love ($55M)...
- **Result**: List of all QB contracts ordered by highest AAV first

### **Step 3: Apply "1.1x Better Player" Logic**
```dart
double highestAAV = positionContracts.first.averageAnnualValue; // $60M (Dak)
double highestPaidPercentile = 0.95; // Assume top contract = 95th percentile player

if (playerPercentile > highestPaidPercentile) {
    return highestAAV * 1.1; // $60M * 1.1 = $66M
}
```
- **Logic**: If player ranks better than 95th percentile, they deserve 110% of highest paid
- **Example**: If Mahomes (93.6%) < 95%, he doesn't get the premium

### **Step 4: Contract Value Interpolation**
```dart
double _interpolateValueFromContracts(double playerPercentile, List<ContractInfo> contracts) {
    // Map 95th percentile → highest contract ($60M)
    // Map 50th percentile → lowest contract * 0.5
    // Linear interpolation between percentiles
}
```
- **Range**: 95th percentile = $60M, 50th percentile = ~$15M  
- **Mahomes Example**: 93.6% → interpolates to ~$58M base value

### **Step 5: Age Adjustment**
```dart
double ageMultiplier = _getAgeMultiplier(player.age, player.position);

// QB Age Curves:
if (age <= 26) return 0.95; // Still developing  
if (age <= 32) return 1.0;  // Prime years
if (age <= 35) return 0.9;  // Decline
return 0.7; // Aging
```
- **Mahomes Example**: Age 29 → 1.0 multiplier (prime)
- **Final Value**: $58M * 1.0 = $58M

### **Step 6: Team Need Multiplier**
```dart
double teamNeedMultiplier = _getTeamNeedMultiplier(player.position, receivingTeam);
```
- **Source**: Team needs CSV with priority weights
- **Example**: Bills need WR (1.5x), don't need QB (0.8x)
- **Mahomes to Bills**: $58M * 0.8 = $46.4M (they have Josh Allen)

### **Final Player Value Formula**
```
Player Value = Contract Interpolation × Age Multiplier × Team Need Multiplier
Mahomes = $58M × 1.0 × 0.8 = $46.4M
```

## **Current Issues & Next Enhancements**

### **Problems with Current Logic:**
1. **Static Percentile Mapping**: Assumes 95th percentile = highest paid (not always true)
2. **Limited Position Coverage**: Only QB/RB/WR/TE have rankings
3. **Simple Team Needs**: Uses static 2026 CSV, not dynamic based on roster
4. **No Contract Context**: Ignores years remaining, guaranteed money
5. **No Positional Scarcity**: All positions treated equally within team needs

### **Next Enhancement Priorities:**

#### **1. Dynamic Percentile-Contract Mapping**
```dart
// Instead of assuming 95th percentile = highest paid
// Calculate actual percentile of each contracted player
double getPlayerActualPercentile(ContractInfo contract) {
    // Use performance metrics to determine where they rank
    // Map contract AAV to actual player performance percentile
}
```

#### **2. Contract Context Awareness**
```dart
double getContractAdjustedValue(ContractInfo contract) {
    double baseValue = contract.averageAnnualValue;
    
    // Discount expiring contracts
    if (contract.yearsRemaining <= 1) baseValue *= 0.8;
    
    // Premium for team control (more years remaining)
    if (contract.yearsRemaining >= 4) baseValue *= 1.1;
    
    // Factor in guaranteed money vs total value
    double guaranteedRatio = contract.guaranteedMoney / contract.totalValue;
    // More guaranteed = higher trade value (certainty)
    
    return baseValue;
}
```

#### **3. Positional Scarcity Multiplier**
```dart
double getPositionalScarcity(String position) {
    // QB: 32 starters league-wide → high scarcity (1.2x)
    // RB: Easy to replace → low scarcity (0.8x) 
    // EDGE: Hard to find elite pass rushers → high scarcity (1.1x)
    
    const Map<String, double> scarcityMultipliers = {
        'QB': 1.2,   // Only 32 starters
        'EDGE': 1.1, // Elite pass rushers rare
        'OT': 1.1,   // Protect the QB
        'CB': 1.0,   // Standard
        'RB': 0.8,   // Replaceable
    };
}
```

#### **4. Dynamic Team Needs Based on Roster Analysis**
```dart
Map<String, double> calculateDynamicTeamNeeds(String team) {
    // Analyze current roster strength by position
    // Factor in recent injuries, age, contract situations
    // Weight by upcoming schedule (pass-heavy opponents = more CB need)
    
    List<NFLPlayer> teamRoster = getTeamRoster(team);
    Map<String, double> positionStrengths = analyzeRosterStrengths(teamRoster);
    
    // Convert strengths to needs (inverse relationship)
    Map<String, double> dynamicNeeds = {};
    for (String position in ALL_POSITIONS) {
        double strength = positionStrengths[position] ?? 0.5;
        dynamicNeeds[position] = 2.0 - strength; // Strong position = low need
    }
    
    return dynamicNeeds;
}
```

#### **5. Multi-Factor Player Rankings**
```dart
double calculateAdvancedPlayerPercentile(NFLPlayer player) {
    double basePercentile = getCurrentRanking(player); // From CSV
    
    // Adjust based on recent performance trends
    double trendMultiplier = getPerformanceTrend(player, lastNGames: 8);
    
    // Adjust based on strength of schedule faced
    double sosMultiplier = getStrengthOfScheduleAdjustment(player);
    
    // Adjust based on supporting cast quality
    double supportMultiplier = getSupportingCastAdjustment(player);
    
    return (basePercentile * trendMultiplier * sosMultiplier * supportMultiplier).clamp(0.0, 1.0);
}
```

## **Immediate Next Steps:**

1. **Show Team Needs in UI** (you requested)
2. **Show Asset Value Breakdown per Team** (you requested)  
3. **Implement Contract Context** (years remaining, guaranteed money)
4. **Add Positional Scarcity Multipliers**
5. **Expand Rankings to All Positions** (use draft data + combine metrics)
6. **Dynamic Team Needs Calculation**
7. **Advanced Player Percentile Calculation**

The current system provides a solid foundation, but these enhancements will make it significantly more sophisticated and realistic for actual NFL trade analysis.