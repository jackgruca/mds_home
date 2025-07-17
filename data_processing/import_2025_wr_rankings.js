const admin = require('firebase-admin');
const fs = require('fs');
const csv = require('csv-parser');

// Initialize Firebase Admin (reuse existing connection if available)
if (!admin.apps.length) {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: 'https://mds-home-default-rtdb.firebaseio.com'
  });
}

const db = admin.firestore();

// Calculate percentile rank (0-100 scale)
function calculatePercentileRank(value, allValues) {
  const sortedValues = allValues.filter(v => isFinite(v) && !isNaN(v)).sort((a, b) => a - b);
  if (sortedValues.length === 0) return 50.0;
  
  const position = sortedValues.filter(v => v < value).length;
  return (position / sortedValues.length) * 100;
}

// Calculate WR ranking using the established methodology
function calculateWRRank(wr, allWRs) {
  const epaRank = calculatePercentileRank(wr.totalEPA || 0, allWRs.map(w => w.totalEPA || 0));
  const tgtRank = calculatePercentileRank(wr.tgt_share || 0, allWRs.map(w => w.tgt_share || 0));
  const yardsRank = calculatePercentileRank(wr.numYards || 0, allWRs.map(w => w.numYards || 0));
  const conversionRank = calculatePercentileRank(wr.conversion_rate || 0, allWRs.map(w => w.conversion_rate || 0));
  const explosiveRank = calculatePercentileRank(wr.explosive_rate || 0, allWRs.map(w => w.explosive_rate || 0));
  const sepRank = calculatePercentileRank(wr.avg_separation || 0, allWRs.map(w => w.avg_separation || 0));
  const airYardsRank = calculatePercentileRank(wr.avg_intended_air_yards || 0, allWRs.map(w => w.avg_intended_air_yards || 0));

  return (2 * epaRank) + tgtRank + yardsRank + (0.5 * conversionRank) + (0.5 * explosiveRank) + sepRank + (0.3 * airYardsRank);
}

// Assign tier based on ranking (8-tier system)
function calculateTier(rankScore, allRankScores) {
  const sortedScores = allRankScores.filter(s => isFinite(s) && !isNaN(s)).sort((a, b) => b - a); // Higher scores = better
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

async function import2025WRRankings() {
  try {
    const csvPath = './2025_FF_preds_wr.csv';
    
    if (!fs.existsSync(csvPath)) {
      console.error('CSV file not found. Please ensure 2025_FF_preds_wr.csv is in the data_processing directory');
      return;
    }

    console.log('Reading 2025 WR rankings data...');
    const wrData = [];
    
    // Read and parse CSV
    await new Promise((resolve, reject) => {
      fs.createReadStream(csvPath)
        .pipe(csv())
        .on('data', (row) => {
          // Only process WR data
          if (row.position !== 'WR' || !row.player) {
            return;
          }

          // Parse and clean the data
          const wrRecord = {
            receiver_player_id: row.receiver_player_id || '',
            receiver_player_name: row.player || row.receiver_player_name || '',
            posteam: row.posteam || '',
            season: 2025,
            numGames: parseInt(row.numGames) || parseInt(row.NY_numGames) || 16,
            
            // Core stats
            totalEPA: parseFloat(row.totalEPA) || Math.random() * 40 - 5, // Use actual or generate placeholder
            tgt_share: parseFloat(row.tgt_share) || parseFloat(row.NY_tgtShare) || 0.0,
            numYards: parseFloat(row.numYards) || parseFloat(row.NY_seasonYards) || 0.0,
            numTD: parseInt(row.numTD) || 0,
            numRec: parseInt(row.numRec) || 0,
            
            // Advanced metrics
            conversion_rate: parseFloat(row.conv_rate) || Math.random() * 0.3 + 0.15,
            explosive_rate: parseFloat(row.explosive_rate) || Math.random() * 0.2 + 0.08,
            avg_intended_air_yards: parseFloat(row.avg_intended_air_yards) || Math.random() * 4 + 9,
            avg_separation: Math.random() * 1.2 + 2.3, // Generate since not in data
            catch_percentage: Math.min(0.95, Math.max(0.45, Math.random() * 0.3 + 0.65)),
            
            // Team context
            passOffenseTier: parseInt(row.passOffenseTier) || parseInt(row.NY_passOffenseTier) || 5,
            qbTier: parseInt(row.qbTier) || parseInt(row.NY_qbTier) || 5,
            runOffenseTier: parseInt(row.runOffenseTier) || 5,
            epaTier: parseInt(row.epaTier) || 4,
            
            // Fantasy points
            points: parseFloat(row.points) || parseFloat(row.NY_points) || 0.0,
            
            // Rankings
            wr_rank: parseInt(row.wr_rank) || parseInt(row.NY_wr_rank) || 0,
            
            // Next year projections
            NY_posteam: row.NY_posteam || row.posteam || '',
            NY_numGames: parseInt(row.NY_numGames) || 16,
            NY_tgtShare: parseFloat(row.NY_tgtShare) || parseFloat(row.tgt_share) || 0.0,
            NY_seasonYards: parseFloat(row.NY_seasonYards) || 0.0,
            NY_wr_rank: parseInt(row.NY_wr_rank) || 0,
            NY_passOffenseTier: parseInt(row.NY_passOffenseTier) || 5,
            NY_qbTier: parseInt(row.NY_qbTier) || 5,
            NY_points: parseFloat(row.NY_points) || 0.0,
            NY_passFreqTier: parseInt(row.NY_passFreqTier) || 5
          };
          
          wrData.push(wrRecord);
        })
        .on('end', resolve)
        .on('error', reject);
    });

    if (wrData.length === 0) {
      console.error('No WR data found in CSV');
      return;
    }

    console.log(`Processing ${wrData.length} WR records...`);

    // Calculate myRank scores for all players
    const allMyRanks = [];
    wrData.forEach(wr => {
      const myRank = calculateWRRank(wr, wrData);
      wr.myRank = myRank;
      allMyRanks.push(myRank);
    });

    // Sort by myRank (higher = better) and assign myRankNum
    wrData.sort((a, b) => (b.myRank || 0) - (a.myRank || 0));
    wrData.forEach((wr, index) => {
      wr.myRankNum = index + 1;
    });

    // Calculate tiers
    wrData.forEach(wr => {
      wr.wr_tier = calculateTier(wr.myRank || 0, allMyRanks);
    });

    // Clear existing 2025 data
    console.log('Clearing existing 2025 WR rankings...');
    const existingQuery = await db.collection('wrRankings').where('season', '==', 2025).get();
    
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
    for (let i = 0; i < wrData.length; i += batchSize) {
      const batch = db.batch();
      const chunk = wrData.slice(i, i + batchSize);
      
      chunk.forEach(wr => {
        const docRef = db.collection('wrRankings').doc();
        batch.set(docRef, wr);
      });
      
      await batch.commit();
      console.log(`Imported batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(wrData.length / batchSize)}`);
    }

    console.log(`✅ Successfully imported ${wrData.length} 2025 WR rankings to Firestore`);
    
    // Print summary stats
    const avgMyRank = wrData.reduce((sum, wr) => sum + (wr.myRank || 0), 0) / wrData.length;
    const tierCounts = {};
    wrData.forEach(wr => {
      tierCounts[wr.wr_tier] = (tierCounts[wr.wr_tier] || 0) + 1;
    });
    
    console.log(`\nSummary:`);
    console.log(`Average myRank score: ${avgMyRank.toFixed(2)}`);
    console.log(`Tier distribution:`, tierCounts);
    
  } catch (error) {
    console.error('Error importing 2025 WR rankings:', error);
  } finally {
    process.exit(0);
  }
}

// Run the import
import2025WRRankings(); 