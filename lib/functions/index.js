const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

// Configuration
const KONNECT_CONFIG = {
  apiKey: functions.config().konnect.api_key,
  walletId: functions.config().konnect.wallet_id,
  baseUrl: functions.config().konnect.is_production === 'true'
    ? 'https://api.konnect.network/api/v2'
    : 'https://api.preprod.konnect.network/api/v2',
};

// Initiate Payment
exports.initiateKonnectPayment = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const {
    orderId,
    amount,
    description,
    firstName,
    lastName,
    email,
    phoneNumber,
    metadata,
  } = data;

  // Validate input
  if (!orderId || !amount) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields'
    );
  }

  try {
    // Create payment record in Firestore
    const paymentRef = admin.firestore().collection('payments').doc();
    
    // Call Konnect API
    const response = await axios.post(
      `${KONNECT_CONFIG.baseUrl}/payments/init-payment`,
      {
        receiverWalletId: KONNECT_CONFIG.walletId,
        token: 'TND',
        amount: amount,
        type: 'immediate',
        description: description || 'Payment',
        acceptedPaymentMethods: ['wallet', 'bank_card', 'e-DINAR'],
        lifespan: 15,
        checkoutForm: true,
        addPaymentFeesToAmount: false,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        email: email,
        orderId: orderId,
        webhook: `https://us-central1-${process.env.GCLOUD_PROJECT}.cloudfunctions.net/konnectWebhook?paymentId=${paymentRef.id}`,
        theme: 'light',
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': KONNECT_CONFIG.apiKey,
        },
      }
    );

    const { payUrl, paymentRef: konnectPaymentRef } = response.data;

    // Save payment to Firestore
    await paymentRef.set({
      userId: userId,
      orderId: orderId,
      amount: amount,
      currency: 'TND',
      status: 'pending',
      paymentRef: konnectPaymentRef,
      payUrl: payUrl,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      metadata: metadata || {},
    });

    return {
      paymentId: paymentRef.id,
      paymentRef: konnectPaymentRef,
      payUrl: payUrl,
    };
  } catch (error) {
    console.error('Error initiating payment:', error);
    throw new functions.https.HttpsError(
      'internal',
      `Failed to initiate payment: ${error.message}`
    );
  }
});

// Verify Payment
exports.verifyKonnectPayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { paymentRef } = data;

  try {
    const response = await axios.get(
      `${KONNECT_CONFIG.baseUrl}/payments/${paymentRef}`,
      {
        headers: {
          'x-api-key': KONNECT_CONFIG.apiKey,
        },
      }
    );

    const paymentData = response.data;
    const isCompleted = paymentData.payment.status === 'completed';

    // Update Firestore if completed
    if (isCompleted) {
      const snapshot = await admin.firestore()
        .collection('payments')
        .where('paymentRef', '==', paymentRef)
        .limit(1)
        .get();

      if (!snapshot.empty) {
        await snapshot.docs[0].ref.update({
          status: 'completed',
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    return {
      verified: isCompleted,
      status: paymentData.payment.status,
    };
  } catch (error) {
    console.error('Error verifying payment:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to verify payment'
    );
  }
});

// Webhook endpoint
exports.konnectWebhook = functions.https.onRequest(async (req, res) => {
  const { payment_ref, paymentId } = req.query;

  try {
    // Verify payment with Konnect
    const response = await axios.get(
      `${KONNECT_CONFIG.baseUrl}/payments/${payment_ref}`,
      {
        headers: {
          'x-api-key': KONNECT_CONFIG.apiKey,
        },
      }
    );

    const paymentData = response.data;
    const status = paymentData.payment.status;

    // Update Firestore
    await admin.firestore().collection('payments').doc(paymentId).update({
      status: status,
      completedAt: status === 'completed'
        ? admin.firestore.FieldValue.serverTimestamp()
        : null,
    });

    // Send notification to user (optional)
    if (status === 'completed') {
      // Send email, push notification, etc.
    }

    res.status(200).send('OK');
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).send('Error');
  }
});