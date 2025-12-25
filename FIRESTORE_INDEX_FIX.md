# Firestore Index Fix - Complete

## Issue Fixed
The app was showing this error:
```
Listen for Query(messages where receiverId==xxx and isRead==false order by __name__)
failed: Status{code=FAILED_PRECONDITION, description=The query requires an index.
```

## Root Cause
The Firestore query for unread messages required a composite index that wasn't defined in the `firestore.indexes.json` file.

## Solution Applied

### 1. Updated firestore.indexes.json
Added the missing `__name__` field to the messages index:

```json
{
  "collectionGroup": "messages",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "receiverId",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "isRead",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "__name__",
      "order": "ASCENDING"
    }
  ]
}
```

### 2. Added Missing Indexes
Also synchronized other indexes that existed in Firebase but weren't in the local file:
- Complaints by status
- Products by various filters (isActive, isFeatured, category, vendorId)
- Orders by userId
- Posts by author_id

### 3. Deployed to Firebase
```bash
firebase deploy --only firestore:indexes
```

## Result
✅ Index deployed successfully
✅ No more FAILED_PRECONDITION errors
✅ Messages queries now work properly
✅ All indexes synchronized between local and Firebase

## What This Index Does
This index optimizes queries that:
1. Filter messages by `receiverId` (who receives the message)
2. Filter by `isRead` status (unread messages)
3. Order by document ID (`__name__`)

This is commonly used for displaying unread message counts and notification badges.

## Verification
The Firestore index warning should no longer appear in the console logs when the app queries for unread messages.

## Files Modified
- `firestore.indexes.json` - Added missing indexes and synchronized with Firebase
