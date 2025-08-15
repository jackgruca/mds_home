const admin = require('firebase-admin');

// Initialize Firebase Admin (reuse existing connection if available)
if (!admin.apps.length) {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: 'https://mds-home-default-rtdb.firebaseio.com'
  });
}

const db = admin.firestore();

// Enhanced 2025 RB data with proper field names
const enhanced2025RBData = [
  { player_name: 'Saquon Barkley', posteam: 'PHI', totalEPA: 18.5, rush_share: 0.68, numYards: 2005, conversion_rate: 0.44, explosive_rate: 0.22, tgt_share: 0.09, numRec: 33, numTD: 13 },
  { player_name: 'Derrick Henry', posteam: 'BAL', totalEPA: 16.8, rush_share: 0.65, numYards: 1921, conversion_rate: 0.48, explosive_rate: 0.25, tgt_share: 0.04, numRec: 11, numTD: 15 },
  { player_name: 'Josh Jacobs', posteam: 'GB', totalEPA: 15.2, rush_share: 0.62, numYards: 1805, conversion_rate: 0.41, explosive_rate: 0.18, tgt_share: 0.07, numRec: 28, numTD: 11 },
  { player_name: 'Christian McCaffrey', posteam: 'SF', totalEPA: 14.8, rush_share: 0.58, numYards: 1650, conversion_rate: 0.45, explosive_rate: 0.19, tgt_share: 0.11, numRec: 45, numTD: 12 },
  { player_name: 'Jahmyr Gibbs', posteam: 'DET', totalEPA: 13.9, rush_share: 0.48, numYards: 1485, conversion_rate: 0.46, explosive_rate: 0.21, tgt_share: 0.10, numRec: 52, numTD: 10 },
  { player_name: 'Joe Mixon', posteam: 'HOU', totalEPA: 12.8, rush_share: 0.59, numYards: 1580, conversion_rate: 0.39, explosive_rate: 0.16, tgt_share: 0.08, numRec: 31, numTD: 9 },
  { player_name: 'Bijan Robinson', posteam: 'ATL', totalEPA: 12.2, rush_share: 0.55, numYards: 1456, conversion_rate: 0.42, explosive_rate: 0.17, tgt_share: 0.12, numRec: 58, numTD: 8 },
  { player_name: 'Alvin Kamara', posteam: 'NO', totalEPA: 11.5, rush_share: 0.52, numYards: 1298, conversion_rate: 0.40, explosive_rate: 0.15, tgt_share: 0.14, numRec: 65, numTD: 7 },
  { player_name: 'Kenneth Walker III', posteam: 'SEA', totalEPA: 10.8, rush_share: 0.61, numYards: 1425, conversion_rate: 0.38, explosive_rate: 0.18, tgt_share: 0.06, numRec: 24, numTD: 8 },
  { player_name: 'James Cook', posteam: 'BUF', totalEPA: 10.2, rush_share: 0.45, numYards: 1245, conversion_rate: 0.43, explosive_rate: 0.20, tgt_share: 0.08, numRec: 32, numTD: 9 },
  { player_name: 'De\'Von Achane', posteam: 'MIA', totalEPA: 9.8, rush_share: 0.42, numYards: 1185, conversion_rate: 0.44, explosive_rate: 0.23, tgt_share: 0.11, numRec: 48, numTD: 7 },
  { player_name: 'David Montgomery', posteam: 'DET', totalEPA: 9.2, rush_share: 0.41, numYards: 1089, conversion_rate: 0.41, explosive_rate: 0.14, tgt_share: 0.07, numRec: 30, numTD: 8 },
  { player_name: 'Rachaad White', posteam: 'TB', totalEPA: 8.9, rush_share: 0.48, numYards: 1156, conversion_rate: 0.37, explosive_rate: 0.13, tgt_share: 0.09, numRec: 38, numTD: 6 },
  { player_name: 'Aaron Jones', posteam: 'MIN', totalEPA: 8.5, rush_share: 0.44, numYards: 1078, conversion_rate: 0.39, explosive_rate: 0.16, tgt_share: 0.10, numRec: 42, numTD: 7 },
  { player_name: 'Kyren Williams', posteam: 'LA', totalEPA: 8.1, rush_share: 0.52, numYards: 1145, conversion_rate: 0.36, explosive_rate: 0.12, tgt_share: 0.06, numRec: 28, numTD: 8 },
  { player_name: 'Tony Pollard', posteam: 'TEN', totalEPA: 7.8, rush_share: 0.56, numYards: 1198, conversion_rate: 0.35, explosive_rate: 0.15, tgt_share: 0.07, numRec: 29, numTD: 6 },
  { player_name: 'Jonathan Taylor', posteam: 'IND', totalEPA: 7.5, rush_share: 0.58, numYards: 1265, conversion_rate: 0.33, explosive_rate: 0.14, tgt_share: 0.05, numRec: 22, numTD: 7 },
  { player_name: 'Najee Harris', posteam: 'PIT', totalEPA: 7.2, rush_share: 0.54, numYards: 1156, conversion_rate: 0.34, explosive_rate: 0.11, tgt_share: 0.08, numRec: 34, numTD: 6 },
  { player_name: 'D\'Andre Swift', posteam: 'CHI', totalEPA: 6.9, rush_share: 0.46, numYards: 985, conversion_rate: 0.37, explosive_rate: 0.13, tgt_share: 0.09, numRec: 38, numTD: 5 },
  { player_name: 'Breece Hall', posteam: 'NYJ', totalEPA: 6.5, rush_share: 0.49, numYards: 1056, conversion_rate: 0.36, explosive_rate: 0.15, tgt_share: 0.11, numRec: 46, numTD: 5 },
  { player_name: 'Javonte Williams', posteam: 'DEN', totalEPA: 6.2, rush_share: 0.43, numYards: 945, conversion_rate: 0.38, explosive_rate: 0.12, tgt_share: 0.08, numRec: 32, numTD: 4 },
  { player_name: 'Rhamondre Stevenson', posteam: 'NE', totalEPA: 5.8, rush_share: 0.51, numYards: 1058, conversion_rate: 0.32, explosive_rate: 0.10, tgt_share: 0.06, numRec: 26, numTD: 5 },
  { player_name: 'Jerome Ford', posteam: 'CLE', totalEPA: 5.5, rush_share: 0.45, numYards: 876, conversion_rate: 0.35, explosive_rate: 0.14, tgt_share: 0.07, numRec: 29, numTD: 4 },
  { player_name: 'Brian Robinson Jr.', posteam: 'WAS', totalEPA: 5.2, rush_share: 0.48, numYards: 945, conversion_rate: 0.33, explosive_rate: 0.09, tgt_share: 0.04, numRec: 18, numTD: 6 },
];

// Calculate percentile rank (0-100 scale)
function calculatePercentileRank(value, allValues) {
  const sortedValues = allValues.filter(v => isFinite(v) && !isNaN(v)).sort((a, b) => a - b);
  if (sortedValues.length === 0) return 50.0;
  
  const position = sortedValues.filter(v => v < value).length;
  return (position / sortedValues.length) * 100;
}

// Calculate RB ranking following the established methodology
function calculateRBRank(rb, allRBs) {
  const epaRank = calculatePercentileRank(rb.totalEPA || 0, allRBs.map(r => r.totalEPA || 0));
  const rushShareRank = calculatePercentileRank(rb.rush_share || 0, allRBs.map(r => r.rush_share || 0));
  const yardsRank = calculatePercentileRank(rb.numYards || 0, allRBs.map(r => r.numYards || 0));
  const conversionRank = calculatePercentileRank(rb.conversion_rate || 0, allRBs.map(r => r.conversion_rate || 0));
  const explosiveRank = calculatePercentileRank(rb.explosive_rate || 0, allRBs.map(r => r.explosive_rate || 0));
  const targetShareRank = calculatePercentileRank(rb.tgt_share || 0, allRBs.map(r => r.tgt_share || 0));
  const receptionRank = calculatePercentileRank(rb.numRec || 0, allRBs.map(r => r.numRec || 0));

  return (2 * epaRank) + rushShareRank + yardsRank + (0.5 * conversionRank) + (0.5 * explosiveRank) + targetShareRank + receptionRank;
}

// Assign tier based on ranking (8-tier system)
function calculateTier(rankScore, allRankScores) {
  const sortedScores = allRankScores.filter(s => isFinite(s) && !isNaN(s)).sort((a, b) => b - a);
  if (sortedScores.length === 0) return 8;
  
  const percentile = calculatePercentileRank(rankScore, sortedScores);
  
  if (percentile >= 87.5) return 1;  // Top 12.5%
  if (percentile >= 75.0) return 2;  // 75-87.5%
  if (percentile >= 62.5) return 3;  // 62.5-75%
  if (percentile >= 50.0) return 4;  // 50-62.5%
  if (percentile >= 37.5) return 5;  // 37.5-50%
  if (percentile >= 25.0) return 6;  // 25-37.5%
  if (percentile >= 12.5) return 7;  // 12.5-25%
  return 8;  // Bottom 12.5%
}

async function import2025RBData() {
  try {
    console.log('Processing 2025 RB rankings...');
    
    // Calculate myRank scores for all players
    const allMyRanks = [];
    enhanced2025RBData.forEach(rb => {
      const myRank = calculateRBRank(rb, enhanced2025RBData);
      rb.myRank = myRank;
      allMyRanks.push(myRank);
    });

    // Sort by myRank (higher = better) and assign myRankNum
    enhanced2025RBData.sort((a, b) => (b.myRank || 0) - (a.myRank || 0));
    enhanced2025RBData.forEach((rb, index) => {
      rb.myRankNum = index + 1;
    });

    // Calculate tiers and add season
    enhanced2025RBData.forEach(rb => {
      rb.rb_tier = calculateTier(rb.myRank || 0, allMyRanks);
      rb.season = '2025';
      rb.rb_rank = rb.myRankNum;
    });

    // Clear existing 2025 data
    console.log('Clearing existing 2025 RB rankings...');
    const existingQuery = await db.collection('rb_rankings').where('season', '==', '2025').get();
    
    if (!existingQuery.empty) {
      const batch = db.batch();
      existingQuery.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      console.log(`Deleted ${existingQuery.docs.length} existing 2025 records`);
    }

    // Import new data in batches
    const batchSize = 10;
    for (let i = 0; i < enhanced2025RBData.length; i += batchSize) {
      const batch = db.batch();
      const chunk = enhanced2025RBData.slice(i, i + batchSize);
      
      chunk.forEach(rb => {
        const docRef = db.collection('rb_rankings').doc();
        batch.set(docRef, rb);
      });
      
      await batch.commit();
      console.log(`Imported batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(enhanced2025RBData.length / batchSize)}`);
    }

    console.log(`✅ Successfully imported ${enhanced2025RBData.length} 2025 RB rankings to Firestore`);
    
    // Print summary stats
    const avgMyRank = enhanced2025RBData.reduce((sum, rb) => sum + (rb.myRank || 0), 0) / enhanced2025RBData.length;
    const tierCounts = {};
    enhanced2025RBData.forEach(rb => {
      tierCounts[rb.rb_tier] = (tierCounts[rb.rb_tier] || 0) + 1;
    });
    
    console.log(`\nSummary:`);
    console.log(`Average myRank score: ${avgMyRank.toFixed(2)}`);
    console.log(`Tier distribution:`, tierCounts);
    
  } catch (error) {
    console.error('Error importing 2025 RB rankings:', error);
  } finally {
    process.exit(0);
  }
}

// Run the import
import2025RBData(); 