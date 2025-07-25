# Firebase Rules Deployment Guide

This guide provides instructions on how to deploy the Firestore and Storage security rules to your Firebase project.

## Prerequisites

1. [Firebase CLI](https://firebase.google.com/docs/cli) installed
2. Logged in to Firebase (`firebase login`)
3. Project initialized with Firebase (`firebase init`)

## Deploy Firestore Rules

1. Make sure you have the `firestore.rules` file in your project root directory.

2. Run the following command:
   ```bash
   firebase deploy --only firestore:rules
   ```

3. Verify in the Firebase Console that your rules have been updated:
   - Go to Firebase Console > Firestore Database > Rules

## Deploy Storage Rules

1. Make sure you have the `storage.rules` file in your project root directory.

2. Run the following command:
   ```bash
   firebase deploy --only storage:rules
   ```

3. Verify in the Firebase Console that your rules have been updated:
   - Go to Firebase Console > Storage > Rules

## Temporary Test Mode (For Development Only)

If you need to quickly test your app without worrying about permissions, you can temporarily set your rules to test mode. **IMPORTANT: Never use these rules in production!**

### Firestore Test Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

### Storage Test Rules
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

## Troubleshooting

If you're still experiencing permission issues after deploying the rules:

1. **Check Authentication**: Make sure your users are properly authenticated
2. **Data Structure**: Ensure your data structure matches what's expected in the rules
3. **Rule Evaluation**: Remember that rules are evaluated based on the existing data structure
4. **Cache**: Firebase may cache rules, so wait a few minutes after deployment

## Important Note

The rules in this project are designed to:
1. Allow users to read and write only their own data
2. Prevent unauthorized access to other users' data
3. Maintain data integrity

Always test your security rules thoroughly before deploying to production. 