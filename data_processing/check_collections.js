const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkCollections() {
  try {
    console.log('🔍 Checking available Firestore collections...');
    
    // Get all collections
    const collections = await db.listCollections();
    console.log('\n📂 Available collections:');
    collections.forEach(collection => {
      console.log(`  - ${collection.id}`);
    });
    
    // Check for depth chart related collections
    const depthChartCollections = collections.filter(col => 
      col.id.toLowerCase().includes('depth') || 
      col.id.toLowerCase().includes('chart')
    );
    
    if (depthChartCollections.length > 0) {
      console.log('\n🎯 Depth chart related collections:');
      for (const collection of depthChartCollections) {
        console.log(`\n📊 Collection: ${collection.id}`);
        const snapshot = await collection.limit(3).get();
        console.log(`   Records: ${snapshot.size}`);
        
        if (!snapshot.empty) {
          const sampleDoc = snapshot.docs[0].data();
          console.log('   Sample fields:', Object.keys(sampleDoc));
        }
      }
    }
    
    // Also check if there's any collection with player data
    console.log('\n🔍 Checking for any collections with player-like data...');
    for (const collection of collections) {
      const snapshot = await collection.limit(1).get();
      if (!snapshot.empty) {
        const sampleDoc = snapshot.docs[0].data();
        const fields = Object.keys(sampleDoc);
        
        // Look for fields that suggest player data
        const playerFields = ['first_name', 'last_name', 'position', 'team', 'depth'];
        const hasPlayerFields = playerFields.some(field => 
          fields.some(f => f.toLowerCase().includes(field.toLowerCase()))
        );
        
        if (hasPlayerFields) {
          console.log(`\n✅ ${collection.id} might have player data:`);
          console.log(`   Fields: ${fields.slice(0, 10).join(', ')}${fields.length > 10 ? '...' : ''}`);
          
          // Get a few more samples
          const moreSnapshot = await collection.limit(3).get();
          moreSnapshot.docs.forEach((doc, index) => {
            const data = doc.data();
            console.log(`   Sample ${index + 1}:`, {
              team: data.team || data.Team,
              position: data.position || data.Position,
              name: `${data.first_name || data.firstName || ''} ${data.last_name || data.lastName || ''}`.trim(),
              season: data.season || data.Season
            });
          });
        }
      }
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
}

checkCollections(); 