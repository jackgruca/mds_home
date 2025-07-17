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

// Enhanced 2025 TE data with proper field names
const enhanced2025TEData = [
  { player_name: 'Brock Bowers', posteam: 'LV', totalEPA: 14.2, tgt_share: 0.22, numYards: 1544, conversion_rate: 0.43, explosive_rate: 0.16, avg_separation: 2.9, catch_percentage: 0.92, numRec: 112, numTD: 7 },
  { player_name: 'Travis Kelce', posteam: 'KC', totalEPA: 13.8, tgt_share: 0.19, numYards: 1285, conversion_rate: 0.46, explosive_rate: 0.18, avg_separation: 2.8, catch_percentage: 0.89, numRec: 97, numTD: 8 },
  { player_name: 'George Kittle', posteam: 'SF', totalEPA: 12.9, tgt_share: 0.17, numYards: 1365, conversion_rate: 0.44, explosive_rate: 0.20, avg_separation: 2.6, catch_percentage: 0.87, numRec: 78, numTD: 9 },
  { player_name: 'Trey McBride', posteam: 'ARI', totalEPA: 11.8, tgt_share: 0.21, numYards: 1205, conversion_rate: 0.42, explosive_rate: 0.14, avg_separation: 2.7, catch_percentage: 0.86, numRec: 111, numTD: 6 },
  { player_name: 'Sam LaPorta', posteam: 'DET', totalEPA: 10.9, tgt_share: 0.16, numYards: 1158, conversion_rate: 0.45, explosive_rate: 0.17, avg_separation: 2.5, catch_percentage: 0.88, numRec: 60, numTD: 8 },
  { player_name: 'Mark Andrews', posteam: 'BAL', totalEPA: 10.1, tgt_share: 0.15, numYards: 985, conversion_rate: 0.41, explosive_rate: 0.15, avg_separation: 2.4, catch_percentage: 0.83, numRec: 55, numTD: 9 },
  { player_name: 'Evan Engram', posteam: 'JAX', totalEPA: 8.9, tgt_share: 0.18, numYards: 945, conversion_rate: 0.39, explosive_rate: 0.12, avg_separation: 2.3, catch_percentage: 0.81, numRec: 47, numTD: 5 },
  { player_name: 'Kyle Pitts', posteam: 'ATL', totalEPA: 8.2, tgt_share: 0.14, numYards: 889, conversion_rate: 0.38, explosive_rate: 0.16, avg_separation: 2.8, catch_percentage: 0.79, numRec: 47, numTD: 6 },
  { player_name: 'Dalton Kincaid', posteam: 'BUF', totalEPA: 7.8, tgt_share: 0.16, numYards: 812, conversion_rate: 0.40, explosive_rate: 0.13, avg_separation: 2.4, catch_percentage: 0.84, numRec: 44, numTD: 4 },
  { player_name: 'David Njoku', posteam: 'CLE', totalEPA: 7.5, tgt_share: 0.17, numYards: 834, conversion_rate: 0.37, explosive_rate: 0.14, avg_separation: 2.2, catch_percentage: 0.80, numRec: 64, numTD: 6 },
  { player_name: 'Jake Ferguson', posteam: 'DAL', totalEPA: 6.9, tgt_share: 0.15, numYards: 745, conversion_rate: 0.36, explosive_rate: 0.11, avg_separation: 2.1, catch_percentage: 0.82, numRec: 59, numTD: 4 },
  { player_name: 'Hunter Henry', posteam: 'NE', totalEPA: 6.5, tgt_share: 0.16, numYards: 698, conversion_rate: 0.35, explosive_rate: 0.10, avg_separation: 2.3, catch_percentage: 0.81, numRec: 66, numTD: 3 },
  { player_name: 'Tucker Kraft', posteam: 'GB', totalEPA: 6.2, tgt_share: 0.14, numYards: 623, conversion_rate: 0.38, explosive_rate: 0.12, avg_separation: 2.2, catch_percentage: 0.83, numRec: 50, numTD: 5 },
  { player_name: 'Cade Otton', posteam: 'TB', totalEPA: 5.9, tgt_share: 0.13, numYards: 589, conversion_rate: 0.34, explosive_rate: 0.09, avg_separation: 2.0, catch_percentage: 0.78, numRec: 59, numTD: 4 },
  { player_name: 'Dallas Goedert', posteam: 'PHI', totalEPA: 5.6, tgt_share: 0.14, numYards: 612, conversion_rate: 0.37, explosive_rate: 0.11, avg_separation: 2.4, catch_percentage: 0.80, numRec: 42, numTD: 3 },
  { player_name: 'T.J. Hockenson', posteam: 'MIN', totalEPA: 5.3, tgt_share: 0.13, numYards: 567, conversion_rate: 0.36, explosive_rate: 0.10, avg_separation: 2.1, catch_percentage: 0.79, numRec: 41, numTD: 3 },
  { player_name: 'Cole Kmet', posteam: 'CHI', totalEPA: 4.9, tgt_share: 0.12, numYards: 534, conversion_rate: 0.33, explosive_rate: 0.08, avg_separation: 2.0, catch_percentage: 0.76, numRec: 47, numTD: 4 },
  { player_name: 'Chigoziem Okonkwo', posteam: 'TEN', totalEPA: 4.6, tgt_share: 0.14, numYards: 498, conversion_rate: 0.32, explosive_rate: 0.09, avg_separation: 1.9, catch_percentage: 0.75, numRec: 52, numTD: 3 },
  { player_name: 'Jonnu Smith', posteam: 'MIA', totalEPA: 4.3, tgt_share: 0.11, numYards: 467, conversion_rate: 0.34, explosive_rate: 0.10, avg_separation: 2.2, catch_percentage: 0.77, numRec: 88, numTD: 4 },
  { player_name: 'Tyler Conklin', posteam: 'NYJ', totalEPA: 3.9, tgt_share: 0.13, numYards: 445, conversion_rate: 0.31, explosive_rate: 0.07, avg_separation: 1.8, catch_percentage: 0.74, numRec: 51, numTD: 3 },
  { player_name: 'Dalton Schultz', posteam: 'HOU', totalEPA: 3.6, tgt_share: 0.12, numYards: 423, conversion_rate: 0.30, explosive_rate: 0.08, avg_separation: 1.9, catch_percentage: 0.73, numRec: 53, numTD: 2 },
  { player_name: 'Pat Freiermuth', posteam: 'PIT', totalEPA: 3.2, tgt_share: 0.11, numYards: 398, conversion_rate: 0.29, explosive_rate: 0.06, avg_separation: 1.7, catch_percentage: 0.72, numRec: 65, numTD: 3 },
];

// Calculate percentile rank (0-100 scale)
function calculatePercentileRank(value, allValues) {
  const sortedValues = allValues.filter(v => isFinite(v) && !isNaN(v)).sort((a, b) => a - b);
  if (sortedValues.length === 0) return 50.0;
  
  const position = sortedValues.filter(v => v < value).length;
  return (position / sortedValues.length) * 100;
}

// Calculate TE ranking following the established methodology
function calculateTERank(te, allTEs) {
  const epaRank = calculatePercentileRank(te.totalEPA || 0, allTEs.map(t => t.totalEPA || 0));
  const tgtRank = calculatePercentileRank(te.tgt_share || 0, allTEs.map(t => t.tgt_share || 0));
  const yardsRank = calculatePercentileRank(te.numYards || 0, allTEs.map(t => t.numYards || 0));
  const conversionRank = calculatePercentileRank(te.conversion_rate || 0, allTEs.map(t => t.conversion_rate || 0));
  const explosiveRank = calculatePercentileRank(te.explosive_rate || 0, allTEs.map(t => t.explosive_rate || 0));
  const sepRank = calculatePercentileRank(te.avg_separation || 0, allTEs.map(t => t.avg_separation || 0));
  const catchRank = calculatePercentileRank(te.catch_percentage || 0, allTEs.map(t => t.catch_percentage || 0));

  return (2 * epaRank) + tgtRank + yardsRank + (0.5 * conversionRank) + (0.5 * explosiveRank) + sepRank + catchRank;
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

async function import2025TEData() {
  try {
    console.log('Processing 2025 TE rankings...');
    
    // Calculate myRank scores for all players
    const allMyRanks = [];
    enhanced2025TEData.forEach(te => {
      const myRank = calculateTERank(te, enhanced2025TEData);
      te.myRank = myRank;
      allMyRanks.push(myRank);
    });

    // Sort by myRank (higher = better) and assign myRankNum
    enhanced2025TEData.sort((a, b) => (b.myRank || 0) - (a.myRank || 0));
    enhanced2025TEData.forEach((te, index) => {
      te.myRankNum = index + 1;
    });

    // Calculate tiers and add season
    enhanced2025TEData.forEach(te => {
      te.te_tier = calculateTier(te.myRank || 0, allMyRanks);
      te.season = '2025';
      te.te_rank = te.myRankNum;
    });

    // Clear existing 2025 data
    console.log('Clearing existing 2025 TE rankings...');
    const existingQuery = await db.collection('te_rankings').where('season', '==', '2025').get();
    
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
    for (let i = 0; i < enhanced2025TEData.length; i += batchSize) {
      const batch = db.batch();
      const chunk = enhanced2025TEData.slice(i, i + batchSize);
      
      chunk.forEach(te => {
        const docRef = db.collection('te_rankings').doc();
        batch.set(docRef, te);
      });
      
      await batch.commit();
      console.log(`Imported batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(enhanced2025TEData.length / batchSize)}`);
    }

    console.log(`✅ Successfully imported ${enhanced2025TEData.length} 2025 TE rankings to Firestore`);
    
    // Print summary stats
    const avgMyRank = enhanced2025TEData.reduce((sum, te) => sum + (te.myRank || 0), 0) / enhanced2025TEData.length;
    const tierCounts = {};
    enhanced2025TEData.forEach(te => {
      tierCounts[te.te_tier] = (tierCounts[te.te_tier] || 0) + 1;
    });
    
    console.log(`\nSummary:`);
    console.log(`Average myRank score: ${avgMyRank.toFixed(2)}`);
    console.log(`Tier distribution:`, tierCounts);
    
  } catch (error) {
    console.error('Error importing 2025 TE rankings:', error);
  } finally {
    process.exit(0);
  }
}

// Run the import
import2025TEData(); 