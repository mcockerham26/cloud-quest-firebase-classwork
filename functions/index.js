
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();

exports.completeDailyQuest = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "You must sign in to complete a quest.",
    );
  }

  const uid = request.auth.uid;
  const progressRef = db
      .collection("users")
      .doc(uid)
      .collection("progress")
      .doc("today");

  const userRef = db.collection("users").doc(uid);

  return db.runTransaction(async (transaction) => {
    const progressDoc = await transaction.get(progressRef);
    const userDoc = await transaction.get(userRef);

    if (progressDoc.exists) {
      return {
        success: true,
        alreadyCompleted: true,
        message: "You already completed today's quest!",
        pointsAwarded: 0,
      };
    }

    transaction.set(progressRef, {
      completed: true,
      completedAt: FieldValue.serverTimestamp(),
      pointsEarned: 10,
      badge: "First Quest",
    });

    const currentPoints = userDoc.exists ?
      (userDoc.data().totalPoints || 0) : 0;

    const existingBadges = userDoc.exists ?
      (userDoc.data().badges || []) : [];

    transaction.set(userRef, {
      totalPoints: currentPoints + 10,
      badges: [...new Set([...existingBadges, "First Quest"])],
    }, {merge: true});

    return {
      success: true,
      alreadyCompleted: false,
      message: "Quest completed! You earned 10 points!",
      pointsAwarded: 10,
      badge: "First Quest",
    };
  });
});
