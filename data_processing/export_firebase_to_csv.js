const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const { parse } = require('json2csv');

// Configuration
const SERVICE_ACCOUNT_PATH = path.join(__dirname, './serviceAccountKey.json');
const DATABASE_URL = 'https://sticktothemodel-d9049.firebaseio.com';
const OUTPUT_DIR = path.join(__dirname, '../assets/data');

// Collections to export
const COLLECTIONS_TO_EXPORT = [
  {
    name: 'playerSeasonStats',
    filename: 'player_stats_2024.csv',
    orderBy: { field: 'fantasy_points_ppr', direction: 'desc' }
  },
  {
    name: 'teamSeasonStats', 
    filename: 'team_stats_2024.csv',
    orderBy: { field: 'team', direction: 'asc' }
  },
  {
    name: 'draftAnalytics',
    filename: 'draft_analytics.csv',
    orderBy: { field: 'pick', direction: 'asc' }
  }
];

// Initialize Firebase Admin
if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
  console.error(`ERROR: Service account key not found at '${SERVICE_ACCOUNT_PATH}'`);
  process.exit(1);
}

const serviceAccount = require(SERVICE_ACCOUNT_PATH);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: DATABASE_URL
});

const db = admin.firestore();

// Ensure output directory exists
if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

async function exportCollection(collectionConfig) {
  const { name, filename, orderBy } = collectionConfig;
  console.log(`\n📊 Exporting ${name} to ${filename}...`);
  
  try {
    // Build query
    let query = db.collection(name);
    if (orderBy) {
      query = query.orderBy(orderBy.field, orderBy.direction);
    }
    
    // Fetch all documents
    const snapshot = await query.get();
    console.log(`Found ${snapshot.size} documents`);
    
    if (snapshot.empty) {
      console.warn(`⚠️  Collection ${name} is empty`);
      return;
    }
    
    // Convert to array of objects
    const data = [];
    snapshot.forEach(doc => {
      data.push({
        id: doc.id,
        ...doc.data()
      });
    });
    
    // Get all unique fields across all documents
    const allFields = new Set();
    data.forEach(item => {
      Object.keys(item).forEach(key => allFields.add(key));
    });
    
    // Convert to CSV
    const csv = parse(data, {
      fields: Array.from(allFields).sort(),
      delimiter: ',',
      quote: '"',
      eol: '\n'  // Explicit line ending
    });
    
    // Write to file
    const outputPath = path.join(OUTPUT_DIR, filename);
    fs.writeFileSync(outputPath, csv);
    console.log(`✅ Exported ${data.length} records to ${outputPath}`);
    
    // Write sample for verification
    console.log(`📋 Sample record:`);
    console.log(JSON.stringify(data[0], null, 2).substring(0, 500) + '...');
    
  } catch (error) {
    console.error(`❌ Error exporting ${name}:`, error);
  }
}

async function createMetadata() {
  const metadata = {
    version: '1.0.0',
    lastUpdated: new Date().toISOString(),
    collections: COLLECTIONS_TO_EXPORT.map(c => ({
      name: c.name,
      filename: c.filename,
      exportedAt: new Date().toISOString()
    })),
    dataSource: 'Firebase Firestore',
    exportScript: 'export_firebase_to_csv.js'
  };
  
  const metadataPath = path.join(OUTPUT_DIR, 'metadata.json');
  fs.writeFileSync(metadataPath, JSON.stringify(metadata, null, 2));
  console.log(`\n📄 Created metadata file at ${metadataPath}`);
}

async function main() {
  console.log('🚀 Starting Firebase to CSV export...');
  console.log(`📁 Output directory: ${OUTPUT_DIR}`);
  
  // Export all collections
  for (const collection of COLLECTIONS_TO_EXPORT) {
    await exportCollection(collection);
  }
  
  // Create metadata file
  await createMetadata();
  
  console.log('\n✨ Export complete!');
  process.exit(0);
}

// Run the export
main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});