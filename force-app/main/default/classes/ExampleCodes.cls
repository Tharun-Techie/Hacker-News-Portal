public with sharing class ExampleCodes {
    public ExampleCodes() {

    }

    public static void encryptDecryptPayload(){
        // 1. Define data and algorithm
        String algorithm = 'AES256';
        Blob clearText = Blob.valueOf('Confidential Data');

        // 2. Generate matching 256-bit key
        Blob secretKey = Crypto.generateAesKey(256);

        // 3. Generate a custom 16-byte (128-bit) Initialization Vector
        // Hardcoded hex below is for demo purposes; always use a secure, random generation technique
        Blob iv = EncodingUtil.convertFromHex('3ad76f92c30b201411deef8a10ccfa42'); 

        // 4. Encrypt the data
        Blob encryptedBlob = Crypto.encrypt(algorithm, secretKey, iv, clearText);

        // 5. Decrypt the data back (requires the exact same IV)
        Blob decryptedBlob = Crypto.decrypt(algorithm, secretKey, iv, encryptedBlob);
        System.debug('Decrypted payload: ' + decryptedBlob.toString());

    }
}