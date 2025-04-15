// firebase/functions/analyticsApi.js (new file)

exports.getAnalyticsData = functions.https.onCall(async (data, context) => {
    const { dataType, filters = {}, useCache = true } = data || {};
    const db = admin.firestore();
    
    // If no data type specified, return available types
    if (!dataType) {
      return {
        availableTypes: [
          'positionDistribution',
          'teamNeeds',
          'positionsByPick',
          'playerDeviations',
          'pickCorrelations'
        ],
        metadata: await getAnalyticsMetadata(db)
      };
    }
    
    try {
      // Check cache first if enabled
      if (useCache) {
        const cachedData = await getCachedData(db, dataType, filters);
        if (cachedData) {
          return {
            data: cachedData,
            fromCache: true,
            cacheTimestamp: cachedData._cacheTimestamp
          };
        }
      }
      
      // Handle specific data types
      let result;
      switch (dataType) {
        case 'positionDistribution':
          result = await getPositionDistribution(db, filters);
          break;
        case 'teamNeeds':
          result = await getTeamNeeds(db, filters);
          break;
        case 'positionsByPick':
          result = await getPositionsByPick(db, filters);
          break;
        case 'playerDeviations':
          result = await getPlayerDeviations(db, filters);
          break;
        case 'pickCorrelations':
          result = await getPickCorrelations(db, filters);
          break;
        default:
          return { error: `Unknown data type: ${dataType}` };
      }
      
      // Cache the result for future use (if caching enabled)
      if (useCache) {
        await cacheResult(db, dataType, filters, result);
      }
      
      return { data: result };
    } catch (error) {
      console.error(`Error getting ${dataType}:`, error);
      return { error: error.toString() };
    }
  });
  
  // Metadata access function
  async function getAnalyticsMetadata(db) {
    const doc = await db.collection('precomputedAnalytics').doc('metadata').get();
    if (!doc.exists) return { status: 'unknown' };
    return doc.data();
  }
  
  // Cache access function
  async function getCachedData(db, dataType, filters) {
    // Create a unique cache key based on dataType and filters
    const cacheKey = createCacheKey(dataType, filters);
    
    const cacheDoc = await db.collection('cachedQueries').doc(cacheKey).get();
    
    if (cacheDoc.exists) {
      const data = cacheDoc.data();
      // Check if cache has expired
      if (data.expires && data.expires.toDate() > new Date()) {
        return {
          ...data.result,
          _cacheTimestamp: data.created
        };
      }
    }
    
    return null;
  }
  
  // Cache storage function
  async function cacheResult(db, dataType, filters, result) {
    const cacheKey = createCacheKey(dataType, filters);
    const now = new Date();
    const expiry = new Date(now.getTime() + 3600000); // 1 hour cache
    
    await db.collection('cachedQueries').doc(cacheKey).set({
      dataType,
      filters,
      result,
      created: admin.firestore.FieldValue.serverTimestamp(),
      expires: expiry
    });
  }
  
  // Helper to create a unique cache key
  function createCacheKey(dataType, filters) {
    const filterString = Object.entries(filters)
      .sort(([keyA], [keyB]) => keyA.localeCompare(keyB))
      .map(([key, value]) => `${key}=${value}`)
      .join('_');
    
    return `${dataType}_${filterString}`.replace(/[\/\.\s]/g, '_');
  }
  
  // Implementation of data access functions (optimized for your data structure)
  // These functions would follow similar patterns to extract the right data