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

// Calculate tier based on percentile ranks
function calculateTier(percentileRank) {
  if (percentileRank >= 90) return 1;      // Top 10%
  if (percentileRank >= 75) return 2;      // Top 25%
  if (percentileRank >= 60) return 3;      // Top 40%
  if (percentileRank >= 45) return 4;      // Top 55%
  if (percentileRank >= 30) return 5;      // Top 70%
  if (percentileRank >= 15) return 6;      // Top 85%
  if (percentileRank >= 5) return 7;       // Top 95%
  return 8;                                // Bottom 5%
}

// Calculate comprehensive WR ranking using 2025 projections methodology
function calculateWRRank(wr, allWRs) {
  // Base projections (40% weight)
  const projectedPointsWeight = 0.20;
  const projectedYardsWeight = 0.20;
  
  // Team context factors (35% weight)  
  const targetShareWeight = 0.15;
  const passOffenseWeight = 0.10;
  const qbTierWeight = 0.10;
  
  // Performance indicators (25% weight)
  const epaTierWeight = 0.15;
  const passFreqWeight = 0.10;
  
  // Extract values with safety checks
  const projectedPoints = parseFloat(wr.points) || 0;
  const projectedYards = parseFloat(wr.numYards) || 0;
  const targetShare = parseFloat(wr.tgt_share) || 0;
  const passOffense = 10 - (parseInt(wr.passOffenseTier) || 8); // Invert tier (1=best becomes 9, 8=worst becomes 2)
  const qbTier = 10 - (parseInt(wr.qbTier) || 8); // Invert tier
  const epaTier = 10 - (parseInt(wr.epaTier) || 8); // Invert tier  
  const passFreq = 10 - (parseInt(wr.NY_passFreqTier) || 8); // Invert tier
  
  // Calculate percentile ranks for each metric
  const allPoints = allWRs.map(w => parseFloat(w.points) || 0);
  const allYards = allWRs.map(w => parseFloat(w.numYards) || 0);
  const allTargetShares = allWRs.map(w => parseFloat(w.tgt_share) || 0);
  
  const pointsPercentile = calculatePercentileRank(projectedPoints, allPoints);
  const yardsPercentile = calculatePercentileRank(projectedYards, allYards);
  const targetSharePercentile = calculatePercentileRank(targetShare, allTargetShares);
  
  // Weighted score calculation
  const score = (
    (pointsPercentile * projectedPointsWeight) +
    (yardsPercentile * projectedYardsWeight) +
    (targetSharePercentile * targetShareWeight) +
    (passOffense * 10 * passOffenseWeight) +  // Scale tier to 0-100 range
    (qbTier * 10 * qbTierWeight) +
    (epaTier * 10 * epaTierWeight) +
    (passFreq * 10 * passFreqWeight)
  );
  
  return score;
}

// Clear existing collection
async function clearCollection(collectionName) {
  const batch = db.batch();
  const querySnapshot = await db.collection(collectionName).get();
  
  querySnapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });
  
  if (querySnapshot.docs.length > 0) {
    await batch.commit();
  }
}

// Import data in batches
async function importDataInBatches(collectionName, data) {
  const batchSize = 10;
  
  for (let i = 0; i < data.length; i += batchSize) {
    const batch = db.batch();
    const chunk = data.slice(i, i + batchSize);
    
    chunk.forEach(record => {
      const docRef = db.collection(collectionName).doc();
      batch.set(docRef, record);
    });
    
    await batch.commit();
    console.log(`Imported batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(data.length / batchSize)} for ${collectionName}`);
  }
}

async function import2025WRProjections() {
  try {
    console.log('🚀 Starting 2025 WR Projections import...');
    
    // Read and process CSV data
    const wrProjections = [];
    
    await new Promise((resolve, reject) => {
      fs.createReadStream('2025_wr_projections.csv')
        .pipe(csv())
        .on('data', (row) => {
          // Skip rows without player data
          if (!row.player || !row.player.trim()) {
            return;
          }
          
          const processedRow = {
            // Player identification
            receiver_player_id: row.receiver_player_id || '',
            player_name: row.player || '',
            position: row.position || 'WR',
            posteam: row.posteam || '',
            season: 2025,
            
            // 2025 Projections
            projected_points: parseFloat(row.points) || 0,
            projected_yards: parseFloat(row.numYards) || 0,
            projected_touchdowns: parseInt(row.numTD) || 0,
            projected_receptions: parseInt(row.numRec) || 0,
            projected_games: parseInt(row.numGames) || 16,
            
            // Team Context (2025)
            tgt_share: parseFloat(row.tgt_share) || 0,
            passOffenseTier: parseInt(row.passOffenseTier) || 8,
            qbTier: parseInt(row.qbTier) || 8,
            runOffenseTier: parseInt(row.runOffenseTier) || 8,
            epaTier: parseInt(row.epaTier) || 8,
            
            // Next Year Context (if different team)
            NY_posteam: row.NY_posteam || row.posteam || '',
            NY_games: parseInt(row.NY_numGames) || 16,
            NY_tgtShare: parseFloat(row.NY_tgtShare) || parseFloat(row.tgt_share) || 0,
            NY_passOffenseTier: parseInt(row.NY_passOffenseTier) || parseInt(row.passOffenseTier) || 8,
            NY_qbTier: parseInt(row.NY_qbTier) || parseInt(row.qbTier) || 8,
            NY_passFreqTier: parseInt(row.NY_passFreqTier) || 8,
            NY_points: parseFloat(row.NY_points) || parseFloat(row.points) || 0,
            
            // Rankings
            wr_rank: parseInt(row.wr_rank) || 0,
            NY_wr_rank: parseInt(row.NY_wr_rank) || parseInt(row.wr_rank) || 0,
            
            // Metadata
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            updated_at: admin.firestore.FieldValue.serverTimestamp()
          };
          
          wrProjections.push(processedRow);
        })
        .on('end', resolve)
        .on('error', reject);
    });
    
    console.log(`📊 Processed ${wrProjections.length} WR projections`);
    
    if (wrProjections.length === 0) {
      console.log('❌ No valid WR projection data found');
      return;
    }
    
    // Calculate myRank scores for all players
    console.log('🔢 Calculating ranking scores...');
    const allMyRanks = [];
    
    wrProjections.forEach(wr => {
      const myRank = calculateWRRank(wr, wrProjections);
      wr.myRank = myRank;
      allMyRanks.push(myRank);
    });

    // Sort by myRank (higher = better) and assign myRankNum
    wrProjections.sort((a, b) => (b.myRank || 0) - (a.myRank || 0));
    wrProjections.forEach((wr, index) => {
      wr.myRankNum = index + 1;
    });

    // Calculate tiers based on myRank percentiles
    wrProjections.forEach(wr => {
      const percentileRank = calculatePercentileRank(wr.myRank || 0, allMyRanks);
      wr.wr_tier = calculateTier(percentileRank);
    });
    
    // Clear existing projections collection
    console.log('🧹 Clearing existing 2025 WR projections...');
    await clearCollection('wr_projections_2025');
    
    // Import new projections
    console.log('📥 Importing 2025 WR projections...');
    await importDataInBatches('wr_projections_2025', wrProjections);
    
    console.log('🎉 2025 WR Projections import completed successfully!');
    
    console.log('\n📊 Import Summary:');
    console.log(`- WR Projections: ${wrProjections.length} records imported`);
    
    // Show tier distribution
    const tierCounts = {};
    wrProjections.forEach(wr => {
      tierCounts[wr.wr_tier] = (tierCounts[wr.wr_tier] || 0) + 1;
    });
    
    console.log('\n🏆 Tier Distribution:');
    Object.entries(tierCounts).sort(([a], [b]) => parseInt(a) - parseInt(b)).forEach(([tier, count]) => {
      console.log(`Tier ${tier}: ${count} players`);
    });
    
    // Show top 10 projected WRs
    console.log('\n🌟 Top 10 Projected WRs for 2025:');
    wrProjections.slice(0, 10).forEach((wr, index) => {
      console.log(`${index + 1}. ${wr.player_name} (${wr.NY_posteam || wr.posteam}) - ${wr.projected_points} pts, ${wr.projected_yards} yds, Tier ${wr.wr_tier}`);
    });

    console.log('\n✅ All data has been successfully imported to Firebase!');

  } catch (error) {
    console.error('Error importing 2025 WR projections:', error);
  } finally {
    process.exit(0);
  }
}

// Run the import
import2025WRProjections(); 