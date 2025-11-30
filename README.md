GateFlow – Secure Gate Access System

GateFlow is a smart access-control system designed to secure gates and restricted areas using automated biometric verification.
The system integrates an iOS application with a Raspberry Pi device and verifies entry using Face Recognition and Voice Identity Matching via Firestore.

How the System Works
Registration Process

The user signs up through the iOS application.

During registration, the user uploads three facial images.

The user records their ID number verbally in English.

The audio is transcribed to text, and the ID number becomes the Firestore document ID.

The user remains in Pending approval status until an admin approves the account.

Entry Attempt

The user arrives at the gate.

A new face image is captured, and the user is asked again to record their ID number.

The new audio is transcribed to text and used to search for the corresponding Firestore document ID.

Two checks are performed:

Face comparison between the stored registration images and the new captured image.

ID/voice comparison between the stored ID and the transcribed voice.

Decision Logic
Facial Match	Voice Match	Result
Yes	Yes	Gate opens
Yes	No	Gate remains closed
No	Yes	Gate remains closed
No	No	Gate remains closed

System Features

Biometric authentication based on both face and voice

Enrollment with three face images to improve recognition accuracy

ID number spoken in English to reduce ambiguity and manipulation attempts

Firestore-based user storage and access logs

Real-time synchronization between iOS, Firestore, and Raspberry Pi

Admin approval required before any user can attempt entry

High-Level Architecture
Component	Technology	Responsibility
iOS App	Swift, Firebase, AVFoundation	User registration, face upload, voice recording, voice transcription
Backend	Firestore	User data, approval status, access logs
Raspberry Pi	Python, DeepFace, Speech Processing, GPIO	Biometric matching and physical gate activation
Hardware	Raspberry Pi + Camera + Motor	Captures face/voice input and opens the gate when valid
Summary

Registration → upload 3 facial images → record ID number → saved in Firestore as document ID → wait for approval.

At the gate → capture face + record ID → transcribe → match face and ID against Firestore.

Only when both match → the gate opens.
