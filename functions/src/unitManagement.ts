import {onDocumentDeleted} from "firebase-functions/v2/firestore";
import {db} from "./firebase";
import {logError, logInfo} from "./logger";

/**
 * Cloud Function: Cascade delete unit subcollections
 *
 * Triggered when a unit is deleted. Deletes all associated documents in
 * subcollections to ensure data integrity.
 */
/**
 * Deletes all documents in a collection in batches.
 *
 * @param {FirebaseFirestore.CollectionReference} collectionRef - The reference to the collection to delete.
 * @param {number} batchSize - The number of documents to delete in each batch.
 */
async function deleteCollectionInBatch(
  collectionRef: FirebaseFirestore.CollectionReference,
  batchSize = 500
) {
  let query = collectionRef.limit(batchSize);
  let snapshot = await query.get();
  let numDeleted = 0;

  while (snapshot.size > 0) {
    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    numDeleted += snapshot.size;

    // Get the next batch
    const lastVisible = snapshot.docs[snapshot.docs.length - 1];
    query = collectionRef.startAfter(lastVisible).limit(batchSize);
    snapshot = await query.get();
  }

  if (numDeleted > 0) {
    logInfo(`Deleted ${numDeleted} documents from ${collectionRef.path}`);
  }
}

export const onUnitDeleted = onDocumentDeleted(
  "properties/{propertyId}/units/{unitId}",
  async (event) => {
    const {propertyId, unitId} = event.params;
    logInfo(`Unit deleted, starting cascade delete for unit ${unitId} in property ${propertyId}`);

    try {
      // Define all subcollections to be deleted
      const subcollections = ["daily_prices", "widget_settings", "bookings"];

      for (const subcollection of subcollections) {
        const collectionRef = db.collection(`properties/${propertyId}/units/${unitId}/${subcollection}`);
        await deleteCollectionInBatch(collectionRef);
      }

      logInfo(`Cascade delete completed for unit ${unitId}`);
    } catch (error) {
      logError(`Error during cascade delete for unit ${unitId}:`, error);
    }
  }
);
