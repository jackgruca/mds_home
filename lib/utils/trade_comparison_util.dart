import '../models/trade_package.dart';

/// Utility class for comparing trade packages
class TradeComparisonUtil {
  /// Compare multiple trade packages and rank them
  static List<Map<String, dynamic>> rankTradePackages(List<TradePackage> packages) {
    if (packages.isEmpty) return [];
    
    List<Map<String, dynamic>> rankedPackages = [];
    
    // Calculate metrics for each package
    for (var package in packages) {
      // Calculate key metrics
      double valueRatio = package.totalValueOffered / package.targetPickValue;
      double valueDelta = package.totalValueOffered - package.targetPickValue;
      int pickQualityScore = _calculatePickQualityScore(package);
      int packageComplexity = _calculatePackageComplexity(package);
      
      // Generate scores
      int valueScore = _scoreValue(valueRatio);
      int qualityScore = _scorePickQuality(pickQualityScore);
      int complexityScore = _scoreComplexity(packageComplexity);
      
      // Overall weighted score
      int overallScore = (valueScore * 0.5 + qualityScore * 0.3 + complexityScore * 0.2).round();
      
      rankedPackages.add({
        'package': package,
        'valueRatio': valueRatio,
        'valueDelta': valueDelta,
        'pickQualityScore': pickQualityScore,
        'packageComplexity': packageComplexity,
        'valueScore': valueScore,
        'qualityScore': qualityScore,
        'complexityScore': complexityScore,
        'overallScore': overallScore,
      });
    }
    
    // Sort by overall score (descending)
    rankedPackages.sort((a, b) => b['overallScore'].compareTo(a['overallScore']));
    
    // Add rank
    for (int i = 0; i < rankedPackages.length; i++) {
      rankedPackages[i]['rank'] = i + 1;
    }
    
    return rankedPackages;
  }
  
  /// Calculate pick quality score
  static int _calculatePickQualityScore(TradePackage package) {
    // Higher score = better pick quality
    int score = 0;
    
    // Score based on pick positions
    for (var pick in package.picksOffered) {
      if (pick.pickNumber <= 32) {
        score += 30; // First round picks very valuable
      } else if (pick.pickNumber <= 64) {
        score += 20; // Second round picks
      } else if (pick.pickNumber <= 100) {
        score += 10; // Third round picks
      } else {
        score += 5; // Later picks
      }
    }
    
    // Penalize future picks (less certain)
    if (package.includesFuturePick) {
      score -= 10;
    }
    
    return score;
  }
  
  /// Calculate package complexity
  static int _calculatePackageComplexity(TradePackage package) {
    // Lower score = less complex (better)
    int complexity = 0;
    
    // More picks = more complex
    complexity += package.picksOffered.length * 10;
    
    // Future picks add complexity
    if (package.includesFuturePick) {
      complexity += 20;
    }
    
    // Additional target picks add complexity
    complexity += package.additionalTargetPicks.length * 15;
    
    return complexity;
  }
  
  /// Score value ratio (0-100)
  static int _scoreValue(double valueRatio) {
    // Optimal is 1.05-1.15
    if (valueRatio >= 1.05 && valueRatio <= 1.15) return 100;
    if (valueRatio > 1.15 && valueRatio <= 1.25) return 90;
    if (valueRatio >= 1.0 && valueRatio < 1.05) return 85;
    if (valueRatio > 1.25 && valueRatio <= 1.35) return 75;
    if (valueRatio >= 0.95 && valueRatio < 1.0) return 70;
    if (valueRatio > 1.35) return 60;
    if (valueRatio >= 0.9 && valueRatio < 0.95) return 50;
    if (valueRatio >= 0.85 && valueRatio < 0.9) return 30;
    return 0; // Very poor value
  }
  
  /// Score pick quality (0-100)
  static int _scorePickQuality(int qualityScore) {
    // Higher quality score is better
    if (qualityScore >= 50) return 100;
    if (qualityScore >= 40) return 90;
    if (qualityScore >= 30) return 80;
    if (qualityScore >= 20) return 60;
    if (qualityScore >= 10) return 40;
    return 20;
  }
  
  /// Score complexity (0-100, lower complexity is better)
  static int _scoreComplexity(int complexity) {
    // Lower complexity is better
    if (complexity <= 10) return 100;
    if (complexity <= 20) return 90;
    if (complexity <= 30) return 80;
    if (complexity <= 40) return 70;
    if (complexity <= 50) return 60;
    if (complexity <= 60) return 50;
    if (complexity <= 80) return 30;
    return 10; // Very complex
  }
}