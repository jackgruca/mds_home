const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function uploadDepthCharts() {
  try {
    console.log('📊 Starting depth chart data upload...');
    
    // Read the JSON file
    const rawData = fs.readFileSync('./depth_charts.json', 'utf8');
    const depthCharts = JSON.parse(rawData);
    
    console.log(`📈 Found ${depthCharts.length} depth chart records to upload`);
    
    // Reference to the depth charts collection
    const depthChartsCollection = db.collection('depthCharts');
    
    // Upload in batches to avoid memory issues
    const batchSize = 500;
    let uploadedCount = 0;
    let batch = db.batch();
    let batchCount = 0;
    
    for (let i = 0; i < depthCharts.length; i++) {
      const depthChart = depthCharts[i];
      
      // Create document reference with the depth_chart_id as the document ID
      const docRef = depthChartsCollection.doc(depthChart.depth_chart_id);
      
      // Add to batch
      batch.set(docRef, depthChart);
      batchCount++;
      
      // Commit batch when it reaches the batch size or at the end
      if (batchCount === batchSize || i === depthCharts.length - 1) {
        await batch.commit();
        uploadedCount += batchCount;
        console.log(`✅ Uploaded batch: ${uploadedCount}/${depthCharts.length} depth chart records`);
        
        // Reset batch
        batch = db.batch();
        batchCount = 0;
        
        // Small delay to avoid overwhelming Firestore
        if (i < depthCharts.length - 1) {
          await new Promise(resolve => setTimeout(resolve, 100));
        }
      }
    }
    
    console.log(`🎉 Successfully uploaded ${uploadedCount} depth chart records to Firestore!`);
    
    // Print some summary statistics
    const seasons = [...new Set(depthCharts.map(dc => dc.season))];
    const teams = [...new Set(depthCharts.map(dc => dc.team))];
    const positionGroups = [...new Set(depthCharts.map(dc => dc.position_group))];
    const players = [...new Set(depthCharts.filter(dc => dc.gsis_id).map(dc => dc.gsis_id))];
    
    console.log('\n📊 Upload Summary:');
    console.log(`   • Seasons: ${seasons.sort().join(', ')}`);
    console.log(`   • Teams: ${teams.length} (${teams.sort().join(', ')})`);
    console.log(`   • Position Groups: ${positionGroups.sort().join(', ')}`);
    console.log(`   • Unique Players: ${players.length}`);
    console.log(`   • Total Records: ${uploadedCount}`);
    
    // Sample of recent records
    const recentRecords = depthCharts
      .filter(dc => dc.season === Math.max(...seasons))
      .slice(0, 5);
    
    console.log('\n🔍 Sample Recent Records:');
    recentRecords.forEach(record => {
      console.log(`   • ${record.display_name} (${record.position}) - ${record.team} - ${record.depth_level} - Week ${record.week} ${record.season}`);
    });
    
  } catch (error) {
    console.error('❌ Error uploading depth chart data:', error);
    process.exit(1);
  }
}

// Run the upload
uploadDepthCharts().then(() => {
  console.log('\n✨ Depth chart upload completed successfully!');
  process.exit(0);
}).catch((error) => {
  console.error('💥 Upload failed:', error);
  process.exit(1);
}); 