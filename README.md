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
For this assignment, I built a Flutter app using Firebase Authentication, Cloud Firestore, and Cloud Functions. I learned how these services work together to manage user accounts, display challenges, and track rewards. I used a callable Cloud Function to award 10 points and the First Quest badge. When I tested the completion button twice, the app correctly kept my total at 10 points instead of awarding extra points. This showed me why checking progress on the server is important for security. The assignment also introduced the AI Quest Coach and its read-only tool, `readMyQuestState`, which is supposed to access a signed-in user's challenge information without changing their rewards. I was not able to finish the live AI integration, so testing the coach's safety boundaries would be my next step.

