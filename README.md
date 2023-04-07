# UniMec
Web 3 solution for patient's all-in-one healthcare experience

## Highlights
- Whenever a user creates a new account, application will create and store a new cryptocurrency wallet in user's mobile keychain (secure storage in both iOS & Android)
  - Our roadmap: wallet's private key will be used to sign the health records, to make sure no one has modified them, but the owner.
- The data in health records has been split into 2 fields
  - private: only owner can understand the data
  - public: visible from the perspective of db
- Patients can decide which data in a health record to be public or private
  - In a web3 world, where every one uses a crypto wallet as a identifier, patient can use the app to book an appointment with any doctor in any hospital, and the records will be kept secretly

# Reference
- Our app has been utilized on the top of [Medic.ly](https://github.com/dc-exe/Health_and_Doctor_Appointment)
  - Old source code has been rewritten to be suitable for latest flutter version.