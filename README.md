# Cloud Quest
CW-02 #03 – Firebase · Cloud Services Classwork

Student: Maya Cockerham

## Project Overview
Cloud Quest is a Flutter application that uses Firebase Authentication, Cloud Firestore, and Cloud Functions to manage a daily challenge and user rewards.

## Features
- Email and password authentication
- Daily challenge retrieved from Firestore
- Authenticated quest completion using a callable Cloud Function
- 10-point reward and First Quest badge
- Firestore transactions to prevent duplicate rewards
- Security rules restricting client writes
- User-specific progress and rewards

## Local Setup
This project uses the Firebase Firestore and Functions Emulators.

1. Install Flutter dependencies using `flutter pub get`.
2. Install function dependencies using `cd functions && npm install`.
3. Start the Firebase Emulators:
   `firebase emulators:start --only functions,firestore`
4. Create the `challenges/today` document in the local Firestore Emulator with a title, description, and points value of 10.
5. Start the Android emulator and run `flutter run`.

Firebase Authentication uses the configured Firebase project.

## Testing
- Sign in with a test account.
- Confirm the daily challenge loads.
- Complete the quest and verify 10 points and the First Quest badge.
- Complete the quest again and verify points are not awarded twice.
- Sign out and verify the login screen appears.

## AI Quest Coach
A live AI Quest Coach is not configured because a model gateway or API key was not provided. The existing reward system does not depend on AI-generated responses.

## Reflection
For this classwork, I created a Flutter application that connects to Firebase services. I used Firebase Authentication to manage user sign-in and Cloud Firestore to load a daily challenge and display user progress. I also created a callable Cloud Function that awards 10 points and a First Quest badge after a user completes the challenge. One important part of this assignment was preventing users from receiving the same reward multiple times. I handled this by using a Firestore transaction to check whether the quest was already completed before awarding points. I also added Firestore security rules to prevent users from directly changing their rewards. I used the Firebase Emulators to test the database and function locally without upgrading to a paid Firebase plan. The AI model integration remains incomplete.
