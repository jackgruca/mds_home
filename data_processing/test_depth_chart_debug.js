const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function debugDepthChartData() {
  try {
    console.log('🔍 Debugging depth chart data structure...');
    
    // Check the correct collection name 'depthCharts'
    const allQuery = db.collection('depthCharts').limit(20);
    const allSnapshot = await allQuery.get();
    
    if (allSnapshot.empty) {
      console.log('❌ No depth chart data found');
      return;
    }
    
    console.log(`📊 Found ${allSnapshot.size} total records`);
    
    // Get unique seasons and teams
    const seasons = new Set();
    const teams = new Set();
    const positions = new Set();
    const positionGroups = new Set();
    const depthTeams = new Set();
    const weeks = new Set();
    
    allSnapshot.docs.forEach(doc => {
      const data = doc.data();
      if (data.season) seasons.add(data.season);
      if (data.team) teams.add(data.team);
      if (data.position) positions.add(data.position);
      if (data.position_group) positionGroups.add(data.position_group);
      if (data.depth_team) depthTeams.add(data.depth_team);
      if (data.week) weeks.add(data.week);
    });
    
    console.log('\n🎯 Available data:');
    console.log('Seasons:', Array.from(seasons).sort());
    console.log('Teams:', Array.from(teams).sort());
    console.log('Weeks:', Array.from(weeks).sort());
    console.log('Positions:', Array.from(positions).sort());
    console.log('Position Groups:', Array.from(positionGroups).sort());
    console.log('Depth Teams:', Array.from(depthTeams).sort());
    
    // Log first few records to see structure
    console.log('\n📋 Sample records:');
    allSnapshot.docs.slice(0, 5).forEach((doc, index) => {
      const data = doc.data();
      console.log(`\n--- Record ${index + 1} ---`);
      console.log('position:', data.position);
      console.log('position_group:', data.position_group);
      console.log('depth_team:', data.depth_team);
      console.log('depth_level:', data.depth_level);
      console.log('first_name:', data.first_name);
      console.log('last_name:', data.last_name);
      console.log('jersey_number:', data.jersey_number);
      console.log('team:', data.team);
      console.log('season:', data.season);
      console.log('week:', data.week);
    });
    
    // Try to get ARI data for the most recent season
    if (teams.has('ARI')) {
      const ariSeasons = Array.from(seasons).sort().reverse(); // Most recent first
      for (const season of ariSeasons) {
        console.log(`\n🔍 Checking ARI ${season}...`);
        const ariQuery = db.collection('depthCharts')
          .where('season', '==', season)
          .where('team', '==', 'ARI')
          .limit(10);
        
        const ariSnapshot = await ariQuery.get();
        if (!ariSnapshot.empty) {
          console.log(`✅ Found ${ariSnapshot.size} ARI ${season} records`);
          
          // Group by position to see the structure
          const positionMap = {};
          ariSnapshot.docs.forEach(doc => {
            const data = doc.data();
            const pos = data.position_group || data.position;
            if (!positionMap[pos]) positionMap[pos] = [];
            positionMap[pos].push(data);
          });
          
          console.log('\n🏈 ARI positions and players:');
          Object.keys(positionMap).sort().forEach(pos => {
            console.log(`\n  ${pos}:`);
            positionMap[pos].forEach(player => {
              console.log(`    ${player.first_name} ${player.last_name} (depth: ${player.depth_team}, week: ${player.week})`);
            });
          });
          break;
        }
      }
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
}

debugDepthChartData(); 