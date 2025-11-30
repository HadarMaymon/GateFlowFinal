GateFlow – Secure Gate Access System

GateFlow is a smart access-control system designed to secure gates and restricted areas using automated biometric verification.
The system integrates an iOS application with a Raspberry Pi device and verifies entry using Face Recognition and Voice Identity Matching through Firestore.

How the System Works
Registration Process

The user signs up through the iOS application.

The user uploads three facial images.

The user records their ID number verbally in English.

The audio is transcribed to text, and the ID number becomes the Firestore document ID.

The user stays in Pending approval status until an admin approves the account.

Entry Attempt

The user arrives at the gate.

A new face image is captured, and the user is asked to record their ID number again.

The audio is transcribed to text and used to search for the matching ID in Firestore.

Two biometric checks are performed:

Face comparison between the stored registration images and the new captured image

ID/voice comparison between the stored ID and the transcribed ID

Decision Logic
Facial Match	Voice Match	Result
Yes	Yes	Gate opens
Yes	No	Gate remains closed
No	Yes	Gate remains closed
No	No	Gate remains closed

Every successful or denied attempt is logged in Firestore with a timestamp and user reference.

System Features

Biometric authentication using both face and voice

Three facial images stored per user for higher recognition accuracy

ID recording in English to prevent manipulation and ambiguity

Firestore-based storage of user profiles and access logs

Real-time synchronization between the iOS app, Raspberry Pi, and Firestore

Admin approval required before users are allowed to attempt entry

High-Level Architecture
Component	Technology	Role
iOS App	Swift, Firebase, AVFoundation	User registration, face upload, voice recording, voice transcription
Backend	Firestore	User storage, approval status, access logging
Edge Device	Raspberry Pi (Python)	Biometric comparison and physical gate trigger
Hardware	Raspberry Pi + Camera + Motor	Captures face/voice input and opens the gate once validated
Summary

Register → upload 3 face images → record ID → ID saved as Firestore document → wait for approval.

At the gate → face capture + ID recording → transcription → biometric comparison vs Firestore.

Gate opens only when both face and voice match.
